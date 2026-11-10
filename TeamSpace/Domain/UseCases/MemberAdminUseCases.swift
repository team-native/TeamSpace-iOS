import Foundation

/// 멤버 관리 [Admin] — 목록 · 역할 · 부서 · 활성 · 조직도 연결 · 추가 · 삭제
/// 최종 판단(마지막 관리자 보호 · 중복 연결 등)은 서버가 해요. 여기선 미리 걸러지는 것만 막아요.
struct MemberAdminUseCase {
    private let repository: MemberAdminRepository

    init(repository: MemberAdminRepository) {
        self.repository = repository
    }

    private func requireAdmin(_ user: AuthUser) throws {
        guard user.can(.manageMembers) else { throw AppError.forbidden("멤버 관리는 관리자만 할 수 있어요.") }
    }

    func fetch(user: AuthUser) async throws -> [ManagedMember] {
        try requireAdmin(user)
        return try await repository.fetchMembers()
    }

    func changeRole(_ member: ManagedMember, to role: UserRole, user: AuthUser) async throws -> ManagedMember {
        try requireAdmin(user)
        guard member.hasAccount else { throw AppError.invalidInput("계정이 없는 구성원이에요.") }
        guard ManagedMember.assignableRoles.contains(role) else {
            throw AppError.invalidInput("FA 는 재정 권한 화면에서 정해 주세요.")
        }
        var updated = member
        updated.roles = try await repository.changeRole(userId: member.id, role: role)
        return updated
    }

    func setActive(_ member: ManagedMember, to isActive: Bool, user: AuthUser) async throws -> ManagedMember {
        try requireAdmin(user)
        guard member.hasAccount else { throw AppError.invalidInput("계정이 없는 구성원이에요.") }
        if !isActive, String(user.id) == member.id { throw AppError.invalidInput("내 계정은 끌 수 없어요.") }
        try await repository.update(userId: member.id, isActive: isActive, department: nil, organizationId: nil)
        var updated = member
        updated.isActive = isActive
        return updated
    }

    func changeDepartment(_ member: ManagedMember, to department: String, user: AuthUser) async throws -> ManagedMember {
        try requireAdmin(user)
        let trimmed = department.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw AppError.invalidInput("부서를 골라 주세요.") }
        try await repository.update(userId: member.id, isActive: nil, department: trimmed, organizationId: nil)
        var updated = member
        updated.department = trimmed
        return updated
    }

    /// 이미 있는 계정을 조직도 구성원과 이어요.
    func link(_ member: ManagedMember, to organizationMember: ManagedMember, user: AuthUser) async throws -> ManagedMember {
        try requireAdmin(user)
        guard member.hasAccount, !member.isLinked else { throw AppError.invalidInput("이미 조직도와 연결된 계정이에요.") }
        guard let organizationId = organizationMember.organizationId, !organizationMember.hasAccount else {
            throw AppError.invalidInput("이미 계정이 연결된 구성원이에요.")
        }
        try await repository.update(userId: member.id, isActive: nil, department: nil, organizationId: organizationId)
        var updated = member
        updated.isLinked = true
        return updated
    }

    func create(_ draft: NewMemberDraft, user: AuthUser) async throws -> CreatedMember {
        try requireAdmin(user)
        var cleaned = draft
        cleaned.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned.email = draft.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        cleaned.department = draft.department.trimmingCharacters(in: .whitespaces)
        guard !cleaned.name.isEmpty else { throw AppError.invalidInput("이름을 적어 주세요.") }
        guard Self.isEmail(cleaned.email) else { throw AppError.invalidInput("이메일 형식을 확인해 주세요.") }
        guard ManagedMember.assignableRoles.contains(cleaned.role) else {
            throw AppError.invalidInput("FA 는 재정 권한 화면에서 정해 주세요.")
        }
        return try await repository.create(cleaned)
    }

    func delete(_ member: ManagedMember, user: AuthUser) async throws {
        try requireAdmin(user)
        guard member.hasAccount else { throw AppError.invalidInput("계정이 없는 구성원이에요.") }
        guard String(user.id) != member.id else { throw AppError.invalidInput("내 계정은 삭제할 수 없어요.") }
        try await repository.delete(userId: member.id)
    }

    static func isEmail(_ text: String) -> Bool {
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !text.contains(" ")
    }
}
