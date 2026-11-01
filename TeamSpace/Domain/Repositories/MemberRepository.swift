import Foundation

protocol MemberRepository: Sendable {
    /// GET /users
    func fetchMembers() async throws -> [Member]
    /// GET /users/{userId}
    func fetchMember(id: Int) async throws -> MemberDetail
    /// GET /organization/tree
    func fetchOrganization() async throws -> OrganizationTree
}
