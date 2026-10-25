import SwiftUI

/// 05-1 · 05-2 결재 (결재 탭 첫 화면)
struct ApprovalListView: View {
    @State private var viewModel: ApprovalListViewModel
    private let onNavigate: (AppRoute) -> Void

    init(viewModel: ApprovalListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.eyebrow)
                        .tsFont(.micro)
                        .foregroundStyle(viewModel.tab == .mine ? Color.tsInk3 : Color.tsPrimary)
                    Text(viewModel.headline)
                        .tsFont(.title2)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, Spacing.xxl)
                Button {
                    onNavigate(.comingSoon(title: "결재 올리기"))
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text("결재 올리기")
                        TSIcon.arrowRight.sized(.base)
                    }
                }
                .buttonStyle(.tsPrimary)
                TSSegmentedControl(
                    items: ApprovalTab.allCases,
                    selection: viewModel.tab,
                    title: { viewModel.title(for: $0) },
                    onSelect: { viewModel.tab = $0 }
                )
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.tabBarInset)
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
            InfoBanner(message: "결재를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            switch viewModel.tab {
            case .mine:
                MyApprovalsSection(viewModel: viewModel, onOpen: open)
            case .received:
                ReceivedApprovalsSection(viewModel: viewModel, onOpen: open)
            }
        }
    }

    private func open(_ item: ApprovalItem) {
        onNavigate(.approvalDetail(documentId: item.id))
    }
}

#Preview {
    NavigationStack {
        ApprovalListView(viewModel: DIContainer.preview().makeApprovalListViewModel(), onNavigate: { _ in })
    }
}
