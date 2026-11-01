import Foundation

final class InquiryRepositoryImpl: InquiryRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMyInquiries() async throws -> [InquirySummary] {
        try await request(Endpoint(method: .get, path: "inquiries/mine"), as: InquiryListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func fetchInquiry(id: Int) async throws -> InquiryDetail {
        try await request(Endpoint(method: .get, path: "inquiries/\(id)"), as: InquiryDetailDTO.self).toEntity()
    }

    func submit(_ draft: InquiryDraft) async throws -> InquirySummary {
        let body = InquirySubmitRequestDTO(
            department: draft.department,
            title: draft.title,
            body: draft.body,
            isAnonymous: draft.isAnonymous,
            followUpOf: draft.followUpOf
        )
        return try await request(Endpoint(method: .post, path: "inquiries", body: body), as: InquirySummaryDTO.self).toEntity()
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
