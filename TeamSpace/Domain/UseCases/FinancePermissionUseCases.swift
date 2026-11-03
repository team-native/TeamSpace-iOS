import Foundation

/// 재정 권한 목록 — Admin 만. 열람 가능한 사람을 먼저, 이름순
struct FetchFinancePermissionsUseCase {
    private let financePermissionRepository: FinancePermissionRepository

    init(financePermissionRepository: FinancePermissionRepository) {
        self.financePermissionRepository = financePermissionRepository
    }

    func execute(user: AuthUser) async throws -> [FinancePermissionMember] {
        guard user.can(.manageFinancePermissions) else { throw AppError.forbidden("재정 권한은 관리자만 바꿀 수 있어요.") }
        return try await financePermissionRepository.fetchMembers().sorted {
            if $0.canViewFinance != $1.canViewFinance { return $0.canViewFinance }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}

/// 재정 열람 권한 주기 · 회수 — Admin 만, Leader · Admin 역할은 회수할 수 없어요.
struct ChangeFinancePermissionUseCase {
    private let financePermissionRepository: FinancePermissionRepository

    init(financePermissionRepository: FinancePermissionRepository) {
        self.financePermissionRepository = financePermissionRepository
    }

    func execute(_ member: FinancePermissionMember, canViewFinance: Bool, user: AuthUser) async throws -> FinancePermissionMember {
        guard user.can(.manageFinancePermissions) else { throw AppError.forbidden("재정 권한은 관리자만 바꿀 수 있어요.") }
        guard canViewFinance || !member.isLockedByRole else {
            throw AppError.invalidInput("Leader · Admin 역할은 재정 정보를 계속 볼 수 있어요.")
        }
        let result = try await financePermissionRepository.update(userId: member.id, canViewFinance: canViewFinance)
        var updated = member
        updated.roles = result.roles
        updated.canViewFinance = result.canViewFinance
        return updated
    }
}
