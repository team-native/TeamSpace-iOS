import SwiftUI

/// 신고 관리 [Admin] — 대기 중 · 전체, 신고마다 숨김 · 삭제 · 반려
struct ReportListView: View {
    @State private var viewModel: ReportListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ReportListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TSSegmentedControl(
                    items: ReportListViewModel.Filter.allCases,
                    selection: viewModel.filter,
                    title: \.title,
                    onSelect: { filter in Task { await viewModel.select(filter) } }
                )
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "신고 관리", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .tsToast($viewModel.toastMessage)
        .confirmationDialog(
            viewModel.decidingReport?.titleText ?? "",
            isPresented: Binding(
                get: { viewModel.decidingReport != nil },
                set: { if !$0 { viewModel.decidingReport = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach(ReportDecision.allCases, id: \.self) { decision in
                Button(decision.title, role: decision == .delete ? .destructive : nil) {
                    Task { await viewModel.decide(decision) }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("숨기거나 삭제하면 구성원에게 글이 보이지 않아요.")
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView()
        case .forbidden:
            InfoBanner(message: "관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .empty:
            InfoBanner(message: viewModel.filter == .pending ? "처리할 신고가 없어요." : "접수된 신고가 없어요.", style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let reports):
            if viewModel.filter == .pending {
                Text(viewModel.pendingCountText)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(reports) { report in
                ReportCard(
                    report: report,
                    isProcessing: viewModel.processingId == report.id,
                    onOpen: report.postTitle == nil ? nil : { onNavigate(.postDetail(id: report.postId)) },
                    onDecide: { viewModel.decidingReport = report }
                )
            }
        }
    }
}

/// 신고 한 건 — 사유 · 글 제목 · 설명 · 처리 결과
private struct ReportCard: View {
    let report: PostReportItem
    let isProcessing: Bool
    let onOpen: (() -> Void)?
    let onDecide: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(report.reason)
                    .tsFont(.caption2Bold)
                    .foregroundStyle(Color.tsNegative)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.tsNegativeSoft, in: Capsule())
                Spacer(minLength: Spacing.sm)
                Text(report.status.title)
                    .tsFont(.caption2)
                    .foregroundStyle(report.status == .pending ? Color.tsPrimary : Color.tsInk3)
            }
            WorkspaceItemText(title: report.titleText, meta: report.detailText)
            if let handled = report.handledText {
                Text(handled)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            if let onOpen {
                WorkspaceLinkRow(title: "글 보기", action: onOpen)
            }
            if report.status == .pending {
                Button("처리하기", action: onDecide)
                    .buttonStyle(.tsPrimary)
                    .disabled(isProcessing)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportListView(
            viewModel: DIContainer.preview().makeReportListViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin])),
            onNavigate: { _ in }
        )
    }
}
