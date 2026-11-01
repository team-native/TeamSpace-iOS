import Foundation

final class RuleRepositoryImpl: RuleRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchRules() async throws -> [RuleSummary] {
        try await request(Endpoint(method: .get, path: "rules"), as: RuleListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchRuleDetail(id: Int) async throws -> RuleDetail {
        try await request(Endpoint(method: .get, path: "rules/\(id)"), as: RuleDetailDTO.self).toEntity()
    }

    func acknowledge(ruleId: Int) async throws -> Date {
        try await request(Endpoint(method: .post, path: "rules/\(ruleId)/acknowledge"), as: RuleAcknowledgeResponseDTO.self)
            .acknowledgedAt
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
