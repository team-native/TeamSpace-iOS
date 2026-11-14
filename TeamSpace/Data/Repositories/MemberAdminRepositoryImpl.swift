import Foundation

final class MemberAdminRepositoryImpl: MemberAdminRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 계정은 GET /admin/users(Admin · 꺼진 계정 포함), 연결 후보는 GET /people 에서 계정 없는 조직도 구성원만
    func fetchMembers() async throws -> [ManagedMember] {
        async let accounts = fetchAll(path: "admin/users", as: ServerAdminUserDTO.self)
        async let people = fetchAll(path: "people", as: ServerPersonDTO.self)
        let candidates = try await people.filter { $0.linked == false && $0.userId == nil }
        return try await accounts.map { $0.toManagedMember() } + candidates.map { $0.toManagedMember() }
    }

    private func fetchAll<Item: Decodable>(path: String, as type: Item.Type) async throws -> [Item] {
        var items: [Item] = []
        var cursor: String?
        repeat {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: path, queryItems: query), as: CursorPageDTO<Item>.self)
            items += page.items
            cursor = page.nextCursor == cursor ? nil : page.nextCursor
        } while cursor != nil && items.count < 1_000
        return items
    }

    func changeRole(userId: String, role: UserRole) async throws -> [UserRole] {
        let response = try await request(
            Endpoint(method: .patch, path: "admin/users/\(Self.escaped(userId))/roles", body: ServerUserRolesDTO(roles: [role.rawValue])),
            as: ServerUserRolesDTO.self
        )
        return response.roles.compactMap { UserRole(rawValue: $0) }
    }

    func update(userId: String, isActive: Bool?, department: String?, organizationId: String?) async throws {
        let body = ServerAdminUserPatchDTO(active: isActive, dept: department, memberId: organizationId)
        _ = try await request(
            Endpoint(method: .patch, path: "admin/users/\(Self.escaped(userId))", body: body),
            as: EmptyResponseDTO.self
        )
    }

    func create(_ draft: NewMemberDraft) async throws -> CreatedMember {
        let body = ServerAdminUserCreateDTO(
            name: draft.name, email: draft.email, dept: draft.department.isEmpty ? nil : draft.department, roles: [draft.role.rawValue]
        )
        return try await request(
            Endpoint(method: .post, path: "admin/users", body: body),
            as: ServerAdminUserCreatedDTO.self
        ).toEntity()
    }

    func delete(userId: String) async throws {
        _ = try await request(Endpoint(method: .delete, path: "admin/users/\(Self.escaped(userId))"), as: EmptyResponseDTO.self)
    }

    private static func escaped(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? id
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
