import Foundation

final class DashboardRepositoryImpl: DashboardRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchHome() async throws -> DashboardHome {
        let endpoint = Endpoint(method: .get, path: "dashboard/home")
        do {
            return try await client.request(endpoint, as: DashboardHomeResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
