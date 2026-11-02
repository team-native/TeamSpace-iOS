import Foundation

protocol MemberRepository: Sendable {
    /// GET /people (커서를 따라 전부)
    func fetchMembers() async throws -> [Member]
    /// GET /people/{id}
    func fetchMember(id: Int) async throws -> MemberDetail
    /// /people 을 부서별로 묶은 조직도
    func fetchOrganization() async throws -> OrganizationTree
}
