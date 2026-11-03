import Foundation
import Observation

/// 가입 요청 관리 [Admin] — GET /admin/signup-requests · POST /admin/signup-requests/{id}/approve
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
    private(set) var isApproving = false
    var toastMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let fetchSignupRequestsUseCase: FetchSignupRequestsUseCase
    private let approveSignupRequestUseCase: ApproveSignupRequestUseCase

    init(
        user: AuthUser,
        fetchSignupRequestsUseCase: FetchSignupRequestsUseCase,
        approveSignupRequestUseCase: ApproveSignupRequestUseCase
    ) {
        self.user = user
        self.fetchSignupRequestsUseCase = fetchSignupRequestsUseCase
        self.approveSignupRequestUseCase = approveSignupRequestUseCase
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

    func startApproval(_ request: SignupRequestItem) {
        temporaryPassword = ""
        approvingRequest = request
    }

    func approve() async {
        guard let request = approvingRequest, canApprove else { return }
        isApproving = true
        defer { isApproving = false }
        do {
            let approved = try await approveSignupRequestUseCase.execute(request, temporaryPassword: temporaryPassword, user: user)
            var items = all
            if let index = items.firstIndex(where: { $0.id == approved.id }) { items[index] = approved }
            state = .loaded(items)
            approvingRequest = nil
            temporaryPassword = ""
            toastMessage = "\(approved.name)님 계정을 만들었어요"
        } catch {
            AppLog.record(error, context: "signup.requests.approve")
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
        case .rejected: return "거절"
        case .unknown: return "확인 중"
        }
    }
}
