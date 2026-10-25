import Foundation

final class FinanceRepositoryImpl: FinanceRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchOverview(month: Date) async throws -> FinanceOverview {
        let endpoint = Endpoint(
            method: .get,
            path: "finance/overview",
            queryItems: [URLQueryItem(name: "month", value: FinanceMonthParameter.string(from: month))]
        )
        return try await request(endpoint, as: FinanceOverviewResponseDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
