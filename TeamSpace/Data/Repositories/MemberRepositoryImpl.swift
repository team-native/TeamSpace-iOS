import Foundation

final class MemberRepositoryImpl: MemberRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMembers() async throws -> [Member] {
        // 동아리 인원이 많지 않아 한 번에 받아 화면에서 검색 · 필터합니다.
        let endpoint = Endpoint(
            method: .get,
            path: "users",
            queryItems: [URLQueryItem(name: "limit", value: "200")]
        )
        return try await request(endpoint, as: MemberListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchMember(id: Int) async throws -> MemberDetail {
        let endpoint = Endpoint(method: .get, path: "users/\(id)")
        return try await request(endpoint, as: MemberDetailResponseDTO.self).toEntity()
    }

    func fetchOrganization() async throws -> OrganizationTree {
        let endpoint = Endpoint(method: .get, path: "organization/tree")
        return try await request(endpoint, as: OrganizationTreeResponseDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
