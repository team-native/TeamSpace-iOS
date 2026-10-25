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

    func fetchContracts(year: Int) async throws -> ContractLedger {
        let endpoint = Endpoint(
            method: .get,
            path: "finance/contracts",
            queryItems: [URLQueryItem(name: "year", value: String(year))]
        )
        return try await request(endpoint, as: ContractLedgerResponseDTO.self).toEntity()
    }

    func fetchContract(id: Int) async throws -> ContractDetail {
        let endpoint = Endpoint(method: .get, path: "finance/contracts/\(id)")
        return try await request(endpoint, as: ContractDetailResponseDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
