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

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
