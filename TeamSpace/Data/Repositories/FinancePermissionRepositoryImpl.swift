import Foundation

final class FinancePermissionRepositoryImpl: FinancePermissionRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMembers() async throws -> [FinancePermissionMember] {
        try await request(
            Endpoint(method: .get, path: "admin/finance/permissions"),
            as: CursorPageDTO<ServerFinancePermissionDTO>.self
        ).items.map { $0.toEntity() }
    }

    func update(userId: Int, canViewFinance: Bool) async throws -> (roles: [UserRole], canViewFinance: Bool) {
        let dto = try await request(
            Endpoint(
                method: .patch,
                path: "admin/finance/permissions/\(userId)",
                body: ServerFinancePermissionRequestDTO(canViewFinance: canViewFinance)
            ),
            as: ServerFinancePermissionDTO.self
        )
        return (dto.roles, dto.canViewFinance)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
