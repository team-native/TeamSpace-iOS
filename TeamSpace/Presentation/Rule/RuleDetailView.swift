import SwiftUI

/// 09-2 문서 상세 · 규칙 — 조항 칩을 누르면 그 조항으로 이동해요.
/// "N건 보기"는 09-3 변경 내역 시트, 바뀐 조항의 "전후 비교 보기"는 09-4로 가요.
struct RuleDetailView: View {
    @State private var viewModel: RuleDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @State private var isShowingRevisions = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: RuleDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    content(proxy: proxy)
                }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "규칙", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.detail != nil {
                RuleReadBar(
                    text: viewModel.readingText,
                    isAcknowledged: viewModel.isAcknowledged,
                    isLoading: viewModel.isAcknowledging,
                    onAcknowledge: { Task { await viewModel.acknowledge() } }
                )
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingRevisions) {
            RuleRevisionSheet(revisions: viewModel.detail?.revisions ?? [])
                .presentationDetents([.height(420)])
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content(proxy: ScrollViewProxy) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 규칙을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            RuleDetailHeader(rule: detail.rule, onShowRevisions: { isShowingRevisions = true })
            RuleArticleChips(articles: detail.articles) { number in
                withAnimation { proxy.scrollTo(number, anchor: .top) }
            }
            ForEach(detail.articles) { article in
                RuleArticleView(article: article, onCompare: { onNavigate(.ruleComparison(id: detail.rule.id)) })
                    .id(article.number)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RuleDetailView(viewModel: DIContainer.preview().makeRuleDetailViewModel(ruleId: 1), onNavigate: { _ in })
    }
}
