import Foundation

final class FinanceSettingsRepositoryImpl: FinanceSettingsRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchPools() async throws -> [FinanceSettingsPool] {
        try await request(Endpoint(method: .get, path: "admin/finance/settings"), as: ServerFinanceSettingsDTO.self)
            .pools.map(\.entity)
    }

    func savePools(_ pools: [FinanceSettingsPool]) async throws -> [FinanceSettingsPool] {
        let body = ServerFinanceSettingsPatchDTO(pools: pools.map(ServerFinanceSettingsDTO.Pool.init))
        return try await request(Endpoint(method: .patch, path: "admin/finance/settings", body: body), as: ServerFinanceSettingsDTO.self)
            .pools.map(\.entity)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}

/// GET · PATCH /admin/finance/settings 응답 `{ pools, flow, notices }` — 앱은 pools 만 써요.
struct ServerFinanceSettingsDTO: Decodable {
    struct Pool: Codable, Equatable {
        let id: String
        let label: String
        let amount: Int
        let ratio: Int
        let color: String?
        let note: String?

        private enum CodingKeys: String, CodingKey { case id, label, amount, ratio, color, note }

        init(_ pool: FinanceSettingsPool) {
            id = pool.id
            label = pool.label
            amount = pool.amount
            ratio = pool.ratio
            color = pool.color
            note = pool.note
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? (try? container.decode(Int.self, forKey: .id)).map(String.init) ?? ""
            label = (try? container.decodeIfPresent(String.self, forKey: .label)) ?? id
            amount = container.money(.amount)
            ratio = container.money(.ratio)
            color = try? container.decodeIfPresent(String.self, forKey: .color)
            note = try? container.decodeIfPresent(String.self, forKey: .note)
        }

        var entity: FinanceSettingsPool {
            FinanceSettingsPool(id: id, label: label, amount: amount, ratio: ratio, color: color, note: note)
        }
    }

    let pools: [Pool]

    private enum CodingKeys: String, CodingKey { case pools }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pools = (try? container.decodeIfPresent([Pool].self, forKey: .pools)) ?? []
    }
}

/// PATCH /admin/finance/settings 요청
struct ServerFinanceSettingsPatchDTO: Encodable, Equatable {
    let pools: [ServerFinanceSettingsDTO.Pool]
}
