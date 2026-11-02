import Foundation

final class InquiryRepositoryImpl: InquiryRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// GET /inquiries — 내 문의 (최신순, id 커서). 상태 칩 숫자를 세려고 끝까지 모아 와요. (100건씩, 최대 5페이지)
    func fetchMyInquiries() async throws -> [InquirySummary] {
        try await fetchAllMine().map { $0.toEntity() }
    }

    /// 서버에 문의 상세 경로가 없어 내 문의 목록에서 찾아요.
    func fetchInquiry(id: Int) async throws -> InquiryDetail {
        guard let item = try await fetchAllMine().first(where: { $0.id == id }) else {
            throw AppError.notFound("문의를 찾을 수 없어요.")
        }
        return item.toDetail()
    }

    func submit(_ draft: InquiryDraft) async throws -> InquirySummary {
        let body = ServerInquiryCreateRequestDTO(
            type: ServerInquiryCreateRequestDTO.defaultType,
            dept: draft.department.serverValue,
            title: draft.title,
            body: draft.body,
            anonymous: draft.isAnonymous
        )
        let created = try await request(Endpoint(method: .post, path: "inquiries", body: body), as: ServerInquiryCreatedDTO.self)
        return InquirySummary(
            id: created.id,
            department: draft.department,
            title: draft.title,
            body: draft.body,
            isAnonymous: draft.isAnonymous,
            createdAt: Date(),
            status: InquiryStatus(serverValue: created.status ?? "접수"),
            reply: nil
        )
    }

    private static let pageSize = 100
    private static let maxPages = 5

    private func fetchAllMine() async throws -> [ServerInquiryDTO] {
        var items: [ServerInquiryDTO] = []
        var cursor: String?
        for _ in 0..<Self.maxPages {
            var query = [URLQueryItem(name: "limit", value: String(Self.pageSize))]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(
                Endpoint(method: .get, path: "inquiries", queryItems: query),
                as: CursorPageDTO<ServerInquiryDTO>.self
            )
            items += page.items.filter { item in !items.contains { $0.id == item.id } }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items
    }

    func fetchInbox() async throws -> InquiryInbox {
        try await request(Endpoint(method: .get, path: "inquiries/inbox"), as: InquiryInboxResponseDTO.self).toEntity()
    }

    func fetchInboxItem(id: Int) async throws -> InquiryInboxItem {
        try await request(Endpoint(method: .get, path: "inquiries/inbox/\(id)"), as: InquiryInboxItemDTO.self).toEntity()
    }

    func assign(inquiryId: Int, assignee: String) async throws -> InquiryInboxItem {
        let endpoint = Endpoint(
            method: .patch,
            path: "inquiries/\(inquiryId)/assignee",
            body: InquiryAssignRequestDTO(assignee: assignee)
        )
        return try await request(endpoint, as: InquiryInboxItemDTO.self).toEntity()
    }

    func reply(inquiryId: Int, draft: InquiryReplyDraft) async throws -> InquiryInboxItem {
        let endpoint = Endpoint(
            method: .post,
            path: "inquiries/\(inquiryId)/reply",
            body: InquiryReplyRequestDTO(kind: draft.kind.rawValue, body: draft.body, referenceRuleId: draft.referenceRuleId)
        )
        return try await request(endpoint, as: InquiryInboxItemDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
