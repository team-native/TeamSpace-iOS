import Foundation
import Observation

/// 가입 요청 관리 [Admin] — GET /admin/signup-requests · POST …/approve · POST …/reject
/// 승인할 때 조직도의 누구인지 골라 `memberId` 로 보내요. (이름만으로는 동명이인을 못 가려요)
@Observable
@MainActor
final class SignupRequestListViewModel {
    enum Filter: CaseIterable, Hashable {
        case pending
        case processed

        var title: String { self == .pending ? "검토 중" : "처리됨" }
    }

    private(set) var state: ViewState<[SignupRequestItem]> = .idle
    var filter: Filter = .pending
    /// 승인 시트에 띄운 요청
    var approvingRequest: SignupRequestItem?
    var temporaryPassword = ""
    /// 연결할 조직도 구성원 id — nil 이면 연결하지 않아요.
    var selectedMemberId: String?
    /// 계정이 아직 없는 조직도 구성원
    private(set) var linkableMembers: [Member] = []
    private(set) var isApproving = false
    /// 반려 시트에 띄운 요청
    var rejectingRequest: SignupRequestItem?
    var rejectReason = ""
    private(set) var isRejecting = false
    var toastMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let fetchSignupRequestsUseCase: FetchSignupRequestsUseCase
    private let approveSignupRequestUseCase: ApproveSignupRequestUseCase
    private let rejectSignupRequestUseCase: RejectSignupRequestUseCase
    private let fetchLinkableMembersUseCase: FetchLinkableMembersUseCase

    init(
        user: AuthUser,
        fetchSignupRequestsUseCase: FetchSignupRequestsUseCase,
        approveSignupRequestUseCase: ApproveSignupRequestUseCase,
        rejectSignupRequestUseCase: RejectSignupRequestUseCase,
        fetchLinkableMembersUseCase: FetchLinkableMembersUseCase
    ) {
        self.user = user
        self.fetchSignupRequestsUseCase = fetchSignupRequestsUseCase
        self.approveSignupRequestUseCase = approveSignupRequestUseCase
        self.rejectSignupRequestUseCase = rejectSignupRequestUseCase
        self.fetchLinkableMembersUseCase = fetchLinkableMembersUseCase
    }

    private var all: [SignupRequestItem] { state.value ?? [] }

    var requests: [SignupRequestItem] {
        all.filter { ($0.status == .reviewing) == (filter == .pending) }
    }

    func count(of filter: Filter) -> Int {
        all.filter { ($0.status == .reviewing) == (filter == .pending) }.count
    }

    /// 비우거나 8자 이상
    var passwordHint: String? {
        let count = temporaryPassword.trimmingCharacters(in: .whitespaces).count
        guard count > 0, count < ApproveSignupRequestUseCase.passwordMinLength else { return nil }
        return "\(ApproveSignupRequestUseCase.passwordMinLength)자 이상으로 정해 주세요."
    }

    var canApprove: Bool { approvingRequest != nil && !isApproving && passwordHint == nil }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchSignupRequestsUseCase.execute(user: user))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "signup.requests.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    var selectedMember: Member? {
        linkableMembers.first { $0.id == selectedMemberId }
    }

    /// "안율 · OL" — 고른 사람이 없으면 "연결 안 함"
    var selectedMemberText: String {
        selectedMember.map(Self.memberText) ?? "연결 안 함"
    }

    static func memberText(_ member: Member) -> String {
        [member.name, member.tag].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// 승인 시트를 열면서 조직도 구성원을 받아요. 같은 이름이 딱 한 명이면 미리 골라 둬요. (확인은 관리자가)
    func startApproval(_ request: SignupRequestItem) async {
        temporaryPassword = ""
        selectedMemberId = nil
        approvingRequest = request
        do {
            linkableMembers = try await fetchLinkableMembersUseCase.execute()
        } catch {
            AppLog.record(error, context: "signup.requests.linkableMembers")
            linkableMembers = []
        }
        guard approvingRequest?.id == request.id else { return }
        let sameName = linkableMembers.filter { $0.name == request.name }
        if sameName.count == 1 { selectedMemberId = sameName[0].id }
    }

    func approve() async {
        guard let request = approvingRequest, canApprove else { return }
        isApproving = true
        defer { isApproving = false }
        do {
            let approved = try await approveSignupRequestUseCase.execute(
                request, temporaryPassword: temporaryPassword, memberId: selectedMember?.id, user: user
            )
            var items = all
            if let index = items.firstIndex(where: { $0.id == approved.id }) { items[index] = approved }
            state = .loaded(items)
            let linked = selectedMember
            approvingRequest = nil
            temporaryPassword = ""
            selectedMemberId = nil
            if let linked { linkableMembers.removeAll { $0.id == linked.id } }
            toastMessage = linked == nil
                ? "\(approved.name)님 계정을 만들었어요"
                : "\(approved.name)님 계정을 만들어 조직도와 연결했어요"
        } catch {
            AppLog.record(error, context: "signup.requests.approve")
            errorMessage = error.userMessage
        }
    }

    var canReject: Bool {
        rejectingRequest != nil && !isRejecting
            && !rejectReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && rejectReason.count <= RejectSignupRequestUseCase.reasonLimit
    }

    func startRejection(_ request: SignupRequestItem) {
        rejectReason = ""
        rejectingRequest = request
    }

    func reject() async {
        guard let request = rejectingRequest, canReject else { return }
        isRejecting = true
        defer { isRejecting = false }
        do {
            let rejected = try await rejectSignupRequestUseCase.execute(request, reason: rejectReason, user: user)
            var items = all
            if let index = items.firstIndex(where: { $0.id == rejected.id }) { items[index] = rejected }
            state = .loaded(items)
            rejectingRequest = nil
            rejectReason = ""
            toastMessage = "\(rejected.name)님 요청을 반려했어요"
        } catch {
            AppLog.record(error, context: "signup.requests.reject")
            errorMessage = error.userMessage
        }
    }
}

extension SignupRequestItem {
    /// "Design · iOS · 9기"
    var metaText: String {
        [department, major, cohort].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// "11.03 요청" · "승인 · 관리자"
    var statusText: String {
        switch status {
        case .reviewing: return requestedAt.map { "\(TSFormat.shortDate($0)) 요청" } ?? "검토 중"
        case .approved: return ["승인", approvedBy].compactMap { $0 }.joined(separator: " · ")
        case .rejected: return ["반려", rejectedBy].compactMap { $0 }.joined(separator: " · ")
        case .unknown: return "확인 중"
        }
    }
}
