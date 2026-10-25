import Foundation

final class WorkspaceRepositoryImpl: WorkspaceRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchHome() async throws -> WorkspaceHome {
        try await request(Endpoint(method: .get, path: "workspace/home"), as: WorkspaceHomeResponseDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
