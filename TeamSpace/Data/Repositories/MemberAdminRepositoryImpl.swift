import Foundation

final class MemberAdminRepositoryImpl: MemberAdminRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMembers() async throws -> [ManagedMember] {
        var members: [ManagedMember] = []
        var cursor: String?
        repeat {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(
                Endpoint(method: .get, path: "people", queryItems: query),
                as: CursorPageDTO<ServerPersonDTO>.self
            )
            members += page.items.map { $0.toManagedMember() }
            cursor = page.nextCursor == cursor ? nil : page.nextCursor
        } while cursor != nil && members.count < 1_000
        return members
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
