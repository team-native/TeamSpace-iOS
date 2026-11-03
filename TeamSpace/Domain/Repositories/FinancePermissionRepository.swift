import Foundation

/// 재정 열람 권한 관리 [Admin]
protocol FinancePermissionRepository: Sendable {
    /// GET /admin/finance/permissions — 전체 사용자
    func fetchMembers() async throws -> [FinancePermissionMember]
    /// PATCH /admin/finance/permissions/{userId} — 주면 FA 추가, 회수하면 FA 제거. 바뀐 역할 · 열람 여부를 돌려줘요.
    func update(userId: Int, canViewFinance: Bool) async throws -> (roles: [UserRole], canViewFinance: Bool)
}
