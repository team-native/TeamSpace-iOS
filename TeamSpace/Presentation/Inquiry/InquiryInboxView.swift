import SwiftUI

/// 11-5 문의 담당자 받은함 [담당자 운영 화면] — 내 부서 문의만 · 검색 · 상태 · 최근 처리 이력
struct InquiryInboxView: View {
    @State private var viewModel: InquiryInboxViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: InquiryInboxViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "문의 받은함", onBack: { dismiss() })
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "문의 담당자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            InquiryInboxHeader(roleTitle: viewModel.roleTitle, department: viewModel.department)
            SearchField(placeholder: "문의 제목, 내용 검색", text: $viewModel.query)
            InquiryDepartmentLockBar(department: viewModel.department)
            InquiryInboxFilterBar(viewModel: viewModel)
            if viewModel.items.isEmpty {
                InfoBanner(message: "조건에 맞는 문의가 없어요.", style: .muted)
            }
            ForEach(viewModel.items) { item in
                InquiryInboxCard(item: item) { onNavigate(.inquiryReview(id: item.id)) }
            }
            if !viewModel.recentLogs.isEmpty {
                InquiryInboxLogCard(logs: viewModel.recentLogs)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InquiryInboxView(
            viewModel: DIContainer.preview().makeInquiryInboxViewModel(user: AuthUser(id: 1, name: "양지우", roles: [.leader])),
            onNavigate: { _ in }
        )
    }
}
