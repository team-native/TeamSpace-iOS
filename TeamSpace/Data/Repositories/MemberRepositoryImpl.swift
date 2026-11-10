import Foundation

final class MemberRepositoryImpl: MemberRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 인원이 많지 않아 커서를 따라 모두 받아서 화면에서 검색 · 필터해요.
    func fetchMembers() async throws -> [Member] {
        var members: [Member] = []
        var cursor: String?
        repeat {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(
                Endpoint(method: .get, path: "people", queryItems: query),
                as: CursorPageDTO<ServerPersonDTO>.self
            )
            members += page.items.map { $0.toEntity() }
            cursor = page.nextCursor == cursor ? nil : page.nextCursor
        } while cursor != nil && members.count < 1_000
        return members
    }

    func fetchMember(id: String) async throws -> MemberDetail {
        try await request(Endpoint(method: .get, path: "people/\(id)"), as: ServerPersonDTO.self).toDetail()
    }

    func fetchOrganization() async throws -> OrganizationTree {
        guard let tree = OrganizationTreeBuilder.build(try await fetchMembers()) else {
            throw AppError.notFound(nil)
        }
        return tree
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
