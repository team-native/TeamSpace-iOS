import Foundation

/// 멤버 관리 [Admin] — GET /people 한 사람을 관리 화면 기준으로 본 모습
struct ManagedMember: Equatable, Identifiable, Sendable {
    /// 관리 API(`/admin/users/{id}`)에 쓰는 계정 id. 계정이 없는 조직도 구성원은 조직도 id 예요.
    let id: String
    /// 조직도 id ("member-02") — 조직도에 없는 계정이면 nil
    let organizationId: String?
    let name: String
    let email: String
    var department: String
    var roles: [UserRole]
    var isActive: Bool
    /// 로그인 계정이 있어요
    let hasAccount: Bool
    /// 계정이 조직도 구성원과 이어졌어요
    var isLinked: Bool

    /// 관리자가 고를 수 있는 역할 — 한 명에 하나. FA 는 재정 권한 화면에서 따로 줘요.
    static let assignableRoles: [UserRole] = [.member, .pm, .leader, .admin]

    /// 지금 역할 — FA 만 있으면 FA, 아무것도 없으면 구성원
    var primaryRole: UserRole {
        Self.assignableRoles.reversed().first { roles.contains($0) } ?? (roles.contains(.fa) ? .fa : .member)
    }
}

/// POST /admin/users 로 만들 사람
struct NewMemberDraft: Equatable, Sendable {
    var name = ""
    var email = ""
    var department = ""
    var role: UserRole = .member
}

/// 새로 만든 계정 — 임시 비밀번호는 이번 한 번만 볼 수 있어요.
struct CreatedMember: Equatable, Sendable {
    let member: ManagedMember
    let temporaryPassword: String
}
