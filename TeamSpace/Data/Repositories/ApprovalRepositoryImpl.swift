import Foundation

final class ApprovalRepositoryImpl: ApprovalRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMyApprovals() async throws -> [ApprovalItem] {
        try await request(Endpoint(method: .get, path: "approvals/mine"), as: ApprovalListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func fetchReceivedApprovals() async throws -> [ApprovalItem] {
        try await request(Endpoint(method: .get, path: "approvals/received"), as: ApprovalListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
