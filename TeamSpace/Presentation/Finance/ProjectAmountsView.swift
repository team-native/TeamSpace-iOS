import SwiftUI

/// 04-9 프로젝트별 금액 (재정 권한이 없으면 04-8 화면)
struct ProjectAmountsView: View {
    @State private var viewModel: ProjectAmountsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectAmountsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: viewModel.isAmountHidden ? "재무" : "프로젝트별 금액", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 280)
        case .empty:
            InfoBanner(message: "올해 수주한 프로젝트가 아직 없어요.", icon: .infoCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "프로젝트별 금액을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let summary):
            if viewModel.isAmountHidden {
                HiddenAmountContent(summary: summary) { onNavigate(.financeAccess) }
            } else {
                AmountSummaryCard(summary: summary, paidPercent: viewModel.paidPercent)
                FilterChipBar(
                    items: ProjectAmountFilter.allCases,
                    selection: viewModel.filter,
                    title: { $0.title },
                    onSelect: { viewModel.filter = $0 }
                )
                ForEach(viewModel.visibleProjects) { project in
                    ProjectAmountCard(project: project)
                }
                if viewModel.hiddenCount > 0 {
                    ShowMoreRow(title: "외 \(viewModel.hiddenCount)개 프로젝트 보기") { viewModel.isExpanded = true }
                }
            }
        }
    }
}

#Preview("04-9 FA") {
    NavigationStack {
        ProjectAmountsView(
            viewModel: DIContainer.preview().makeProjectAmountsViewModel(year: 2026, user: AuthUser(id: 1, name: "김민준", roles: [.fa])),
            onNavigate: { _ in }
        )
    }
}

#Preview("04-8 권한 없음") {
    NavigationStack {
        ProjectAmountsView(
            viewModel: DIContainer.preview().makeProjectAmountsViewModel(year: 2026, user: AuthUser(id: 1, name: "옥물결", roles: [.member])),
            onNavigate: { _ in }
        )
    }
}
