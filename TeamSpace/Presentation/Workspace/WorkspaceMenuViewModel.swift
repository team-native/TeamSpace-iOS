import Foundation
import Observation

/// 07-3 내 공간 (내 공간 탭 첫 화면)
@Observable
@MainActor
final class WorkspaceMenuViewModel {
    private(set) var receivedState: ViewState<[ApprovalItem]> = .idle
    private(set) var affiliation: String?
    let user: AuthUser

    private let fetchApprovalBoxUseCase: FetchApprovalBoxUseCase
    private let fetchWorkspaceHomeUseCase: FetchWorkspaceHomeUseCase

    init(
        user: AuthUser,
        fetchApprovalBoxUseCase: FetchApprovalBoxUseCase,
        fetchWorkspaceHomeUseCase: FetchWorkspaceHomeUseCase
    ) {
        self.user = user
        self.fetchApprovalBoxUseCase = fetchApprovalBoxUseCase
        self.fetchWorkspaceHomeUseCase = fetchWorkspaceHomeUseCase
    }

    /// 내가 확인해야 하는 받은 결재 (최근 순)
    var waitingApprovals: [ApprovalItem] {
        (receivedState.value ?? []).filter { $0.status.isWaiting }
    }

    var latestWaiting: ApprovalItem? {
        waitingApprovals.first
    }

    func load() async {
        async let profile: Void = loadAffiliation()
        async let approvals: Void = loadApprovals()
        _ = await (profile, approvals)
    }

    private func loadAffiliation() async {
        do {
            affiliation = try await fetchWorkspaceHomeUseCase.execute().affiliation
        } catch {
            // 소속은 없어도 화면을 그릴 수 있어요.
            AppLog.record(error, context: "workspace.menu.affiliation")
        }
    }

    private func loadApprovals() async {
        if receivedState.value == nil { receivedState = .loading }
        do {
            receivedState = .loaded(try await fetchApprovalBoxUseCase.execute().received)
        } catch AppError.forbidden {
            receivedState = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.menu.approvals")
            if receivedState.value == nil { receivedState = .failed(error) }
        }
    }
}
