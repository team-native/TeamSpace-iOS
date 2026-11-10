import Foundation
import Observation

/// 멤버 관리 [Admin] — GET /people · PATCH /admin/users/{id}(/roles) · POST · DELETE /admin/users
/// 바꾸면 바로 서버에 보내고, 성공하면 목록만 고쳐요.
@Observable
@MainActor
final class MemberAdminViewModel {
    private(set) var state: ViewState<[ManagedMember]> = .idle
    var query = ""
    /// 편집 시트에 띄운 사람 (id 만 들고, 내용은 목록에서 읽어요)
    var editingMemberId: String?
    /// 멤버 추가 시트
    var isAddPresented = false
    var draft = NewMemberDraft()
    /// 방금 만든 계정 — 임시 비밀번호를 한 번만 보여줘요.
    var createdMember: CreatedMember?
    /// 삭제 확인
    var deletingMember: ManagedMember?
    private(set) var processingId: String?
    private(set) var isCreating = false
    var toastMessage: String?
    var errorMessage: String?

    let user: AuthUser
    private let useCase: MemberAdminUseCase

    init(user: AuthUser, useCase: MemberAdminUseCase) {
        self.user = user
        self.useCase = useCase
    }

    private var all: [ManagedMember] { state.value ?? [] }

    /// 계정이 있는 사람 — 켜진 계정 먼저, 이름순 · 이름 · 이메일 · 부서 검색
    var members: [ManagedMember] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        return all
            .filter(\.hasAccount)
            .filter { keyword.isEmpty || "\($0.name) \($0.email) \($0.department)".localizedCaseInsensitiveContains(keyword) }
            .sorted { ($0.isActive ? 0 : 1, $0.name) < ($1.isActive ? 0 : 1, $1.name) }
    }

    /// 계정이 아직 없는 조직도 구성원 — 계정 연결 후보
    var unlinkedOrganizationMembers: [ManagedMember] {
        all.filter { !$0.hasAccount && $0.organizationId != nil }.sorted { $0.name < $1.name }
    }

    /// "계정 20명 · 꺼짐 1명 · 조직도 미연결 3명"
    var summaryText: String {
        let accounts = all.filter(\.hasAccount)
        var parts = ["계정 \(accounts.count)명"]
        let inactive = accounts.filter { !$0.isActive }.count
        if inactive > 0 { parts.append("꺼짐 \(inactive)명") }
        let unlinked = accounts.filter { !$0.isLinked }.count
        if unlinked > 0 { parts.append("조직도 미연결 \(unlinked)명") }
        return parts.joined(separator: " · ")
    }

    /// 지금 쓰는 부서 이름들 (서버 dept 는 자유 문자열이라 목록에서 모아요)
    var departmentOptions: [String] {
        Array(Set(all.map(\.department).filter { !$0.isEmpty })).sorted()
    }

    var editingMember: ManagedMember? {
        editingMemberId.flatMap { id in all.first { $0.id == id } }
    }

    func isMe(_ member: ManagedMember) -> Bool { String(user.id) == member.id }

    var canCreate: Bool {
        !isCreating && !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            && MemberAdminUseCase.isEmail(draft.email.trimmingCharacters(in: .whitespaces))
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await useCase.fetch(user: user))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "member.admin.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func changeRole(_ member: ManagedMember, to role: UserRole) async {
        guard member.primaryRole != role else { return }
        await run(member, context: "member.admin.role") {
            let updated = try await self.useCase.changeRole(member, to: role, user: self.user)
            return (updated, "\(updated.name)님 역할을 \(role.title)(으)로 바꿨어요")
        }
    }

    func setActive(_ member: ManagedMember, to isActive: Bool) async {
        guard member.isActive != isActive else { return }
        await run(member, context: "member.admin.active") {
            let updated = try await self.useCase.setActive(member, to: isActive, user: self.user)
            return (updated, isActive ? "\(updated.name)님 계정을 다시 켰어요" : "\(updated.name)님 계정을 껐어요")
        }
    }

    func changeDepartment(_ member: ManagedMember, to department: String) async {
        guard member.department != department else { return }
        await run(member, context: "member.admin.dept") {
            let updated = try await self.useCase.changeDepartment(member, to: department, user: self.user)
            return (updated, "\(updated.name)님 부서를 \(updated.department)(으)로 바꿨어요")
        }
    }

    func link(_ member: ManagedMember, to organizationMember: ManagedMember) async {
        await run(member, context: "member.admin.link") {
            let updated = try await self.useCase.link(member, to: organizationMember, user: self.user)
            return (updated, "\(updated.name)님 계정을 조직도의 \(organizationMember.name)님과 연결했어요")
        }
        // 연결에 성공했으면 그 조직도 구성원은 더 이상 후보가 아니에요.
        if all.first(where: { $0.id == member.id })?.isLinked == true {
            state = .loaded(all.filter { $0.id != organizationMember.id })
        }
    }

    func startAdd() {
        draft = NewMemberDraft()
        isAddPresented = true
    }

    func create() async {
        guard canCreate else { return }
        isCreating = true
        defer { isCreating = false }
        do {
            let created = try await useCase.create(draft, user: user)
            state = .loaded(all + [created.member])
            isAddPresented = false
            createdMember = created
        } catch {
            AppLog.record(error, context: "member.admin.create")
            errorMessage = error.userMessage
        }
    }

    func delete(_ member: ManagedMember) async {
        guard processingId == nil else { return }
        processingId = member.id
        defer { processingId = nil }
        do {
            try await useCase.delete(member, user: user)
            state = .loaded(all.filter { $0.id != member.id })
            if editingMemberId == member.id { editingMemberId = nil }
            toastMessage = "\(member.name)님 계정을 삭제했어요"
        } catch {
            AppLog.record(error, context: "member.admin.delete")
            errorMessage = error.userMessage
        }
    }

    /// 한 사람씩 처리하고, 성공하면 목록의 그 사람을 바꿔요.
    private func run(
        _ member: ManagedMember,
        context: String,
        _ action: @escaping () async throws -> (ManagedMember, String)
    ) async {
        guard processingId == nil else { return }
        processingId = member.id
        defer { processingId = nil }
        do {
            let (updated, message) = try await action()
            var items = all
            if let index = items.firstIndex(where: { $0.id == updated.id }) { items[index] = updated }
            state = .loaded(items)
            toastMessage = message
        } catch {
            AppLog.record(error, context: context)
            errorMessage = error.userMessage
        }
    }
}

extension UserRole {
    /// 멤버 관리 화면 이름
    var title: String {
        switch self {
        case .member: return "구성원"
        case .pm: return "PM"
        case .leader: return "Leader"
        case .fa: return "FA"
        case .admin: return "Admin"
        case .unknown: return "구성원"
        }
    }
}

extension ManagedMember {
    /// "Design · 구성원" / "PMO · PM"
    var metaText: String {
        [department, primaryRole.title].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
