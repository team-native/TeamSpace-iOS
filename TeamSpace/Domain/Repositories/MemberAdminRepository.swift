import Foundation

/// 멤버 관리 [Admin] — 서버 `require_admin`
protocol MemberAdminRepository: Sendable {
    /// GET /people (커서를 따라 전부) — 계정 · 조직도 연결 여부 · 활성 상태 포함
    func fetchMembers() async throws -> [ManagedMember]
    /// PATCH /admin/users/{id}/roles — 역할 하나. 마지막 관리자를 내리면 409
    func changeRole(userId: String, role: UserRole) async throws -> [UserRole]
    /// PATCH /admin/users/{id} — 바꿀 값만 보내요. `organizationId` 는 조직도 연결(이미 다른 계정이 있으면 409)
    func update(userId: String, isActive: Bool?, department: String?, organizationId: String?) async throws
    /// POST /admin/users — 임시 비밀번호는 이 응답에서만 받아요.
    func create(_ draft: NewMemberDraft) async throws -> CreatedMember
    /// DELETE /admin/users/{id} — 나 자신 · 마지막 관리자는 409
    func delete(userId: String) async throws
}
