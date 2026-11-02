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

    /// 답변받은 문의의 후속 문의는 같은 문의에 추가 메시지로(POST /inquiries/{id}/comments), 나머지는 새 문의로 접수해요.
    func submit(_ draft: InquiryDraft) async throws -> InquirySummary {
        if let original = draft.followUpOf {
            return try await addFollowUp(to: original, draft: draft)
        }
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

    /// 추가 메시지는 제목 없이 내용만 보내요.
    private func addFollowUp(to inquiryId: Int, draft: InquiryDraft) async throws -> InquirySummary {
        let endpoint = Endpoint(
            method: .post,
            path: "inquiries/\(inquiryId)/comments",
            body: ServerInquiryCommentRequestDTO(text: draft.body)
        )
        _ = try await request(endpoint, as: IgnoredJSONValue.self)
        if let original = try? await fetchAllMine().first(where: { $0.id == inquiryId }) {
            return original.toEntity()
        }
        return InquirySummary(
            id: inquiryId, department: draft.department, title: draft.title, body: draft.body,
            isAnonymous: draft.isAnonymous, createdAt: Date(), status: .answered, reply: nil
        )
    }

    private static let pageSize = 100
    private static let maxPages = 5

    private func fetchAllMine() async throws -> [ServerInquiryDTO] {
        try await fetchAll(path: "inquiries")
    }

    private func fetchAll(path: String) async throws -> [ServerInquiryDTO] {
        var items: [ServerInquiryDTO] = []
        var cursor: String?
        for _ in 0..<Self.maxPages {
            var query = [URLQueryItem(name: "limit", value: String(Self.pageSize))]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(
                Endpoint(method: .get, path: path, queryItems: query),
                as: CursorPageDTO<ServerInquiryDTO>.self
            )
            items += page.items.filter { item in !items.contains { $0.id == item.id } }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items
    }

    /// GET /admin/inquiries — 담당 부서 문의 (Admin 은 전체). 서버는 담당자 목록을 주지 않아요.
    func fetchInbox() async throws -> InquiryInbox {
        let items = try await fetchAll(path: "admin/inquiries")
        let departments = items.map(\.departmentValue).filter { $0 != .unknown }
        let counts = Dictionary(departments.map { ($0, 1) }, uniquingKeysWith: +)
        let department = counts.max { $0.value < $1.value }?.key ?? .unknown
        return InquiryInbox(department: department, items: items.map { $0.toInboxItem() }, assignees: [])
    }

    /// 서버에 담당자용 상세 경로가 없어 받은함에서 찾아요.
    func fetchInboxItem(id: Int) async throws -> InquiryInboxItem {
        guard let item = try await fetchAll(path: "admin/inquiries").first(where: { $0.id == id }) else {
            throw AppError.notFound("문의를 찾을 수 없어요.")
        }
        return item.toInboxItem()
    }

    /// PATCH /admin/inquiries/{id} — 검토 중으로 바꿔요. 서버가 담당자를 저장하지 않으면 화면에만 배정해요.
    func assign(inquiryId: Int, assignee: String) async throws -> InquiryInboxItem {
        let body = ServerInquiryPatchRequestDTO(status: InquiryStatus.reviewing.serverValue, assignee: assignee)
        _ = try await request(Endpoint(method: .patch, path: "admin/inquiries/\(inquiryId)", body: body), as: IgnoredJSONValue.self)
        let item = try await fetchInboxItem(id: inquiryId)
        guard item.assignee == nil else { return item }
        return InquiryInboxItem(
            inquiry: item.inquiry, authorName: item.authorName, assignee: assignee,
            history: item.history, reference: item.reference
        )
    }

    /// 답변은 POST /admin/inquiries/{id}/answer, 반려는 PATCH /admin/inquiries/{id} `{status: "반려", answer}`
    func reply(inquiryId: Int, draft: InquiryReplyDraft) async throws -> InquiryInboxItem {
        switch draft.kind {
        case .answer:
            let body = ServerInquiryAnswerRequestDTO(text: draft.body, referenceRuleId: draft.referenceRuleId)
            _ = try await request(Endpoint(method: .post, path: "admin/inquiries/\(inquiryId)/answer", body: body), as: IgnoredJSONValue.self)
        case .reject:
            let body = ServerInquiryPatchRequestDTO(status: InquiryStatus.rejected.serverValue, answer: draft.body)
            _ = try await request(Endpoint(method: .patch, path: "admin/inquiries/\(inquiryId)", body: body), as: IgnoredJSONValue.self)
        }
        return try await fetchInboxItem(id: inquiryId)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
