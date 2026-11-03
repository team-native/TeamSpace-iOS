import Foundation

/// 재정 열람 권한 한 사람 — GET /admin/finance/permissions
struct FinancePermissionMember: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
    var roles: [UserRole]
    var canViewFinance: Bool

    /// Leader · Admin 은 역할 때문에 늘 열람해요. (서버는 회수할 때 FA 만 빼요)
    var isLockedByRole: Bool { !Set(roles).isDisjoint(with: [.leader, .admin]) }
}
