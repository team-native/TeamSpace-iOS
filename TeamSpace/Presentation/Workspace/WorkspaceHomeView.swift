import SwiftUI

/// 07-1 내 공간 대시보드 (07-3 내 공간 → 업무 대시보드)
struct WorkspaceHomeView: View {
    @State private var viewModel: WorkspaceHomeViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: WorkspaceHomeViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                WorkspaceProfileCard(
                    user: viewModel.user,
                    affiliation: viewModel.state.value?.affiliation,
                    onEdit: { onNavigate(.comingSoon(title: "프로필 편집")) }
                )
                ScreenTitle(title: viewModel.greeting, subtitle: viewModel.dateLine())
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            WorkspaceTopBar(onBack: { dismiss() }, onMenu: { onNavigate(.comingSoon(title: "설정")) })
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "내 공간을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let home):
            WorkspaceHomeCards(home: home, schedules: viewModel.upcomingSchedules, onNavigate: onNavigate)
        }
    }
}

/// 07-1 카드 묶음 — To-do · 알림 · 결재 · 프로젝트 · 일정 · 기록
private struct WorkspaceHomeCards: View {
    let home: WorkspaceHome
    let schedules: [WorkspaceSchedule]
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        WorkspaceTodoCard(todo: home.todo, onOpen: { onNavigate(.workspaceTodos) })
        if let notification = home.notification {
            WorkspaceNotificationCard(notification: notification, onOpen: { onNavigate(.notificationCenter) })
        }
        WorkspaceApprovalCard(
            received: home.receivedApproval,
            submitted: home.submittedDocument,
            onReview: { onNavigate(.approvalDetail(documentId: $0)) },
            onSubmitted: { onNavigate(.comingSoon(title: "내가 제출한 문서")) }
        )
        WorkspaceProjectsCard(projects: home.projects, onOpen: { onNavigate(.comingSoon(title: "참여 프로젝트")) })
        WorkspaceSchedulesCard(schedules: schedules, onOpen: { onNavigate(.comingSoon(title: "일정")) })
        WorkspaceRecordsCard(records: home.records, onOpen: { onNavigate(.comingSoon(title: $0)) })
        WorkspaceNote()
    }
}

#Preview {
    NavigationStack {
        WorkspaceHomeView(
            viewModel: DIContainer.preview().makeWorkspaceHomeViewModel(
                user: AuthUser(id: 1, name: "옥물결", roles: [.member])
            ),
            onNavigate: { _ in }
        )
    }
}
