import SwiftUI

/// 09-4 규칙 개정 비교 — 바뀐 조항의 이전 · 변경 후 본문을 나란히 보고 읽음 확인해요.
/// 09-2 와 같은 상세 데이터를 쓰므로 RuleDetailViewModel 을 함께 써요.
struct RuleComparisonView: View {
    @State private var viewModel: RuleDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: RuleDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
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
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "개정 전후 비교", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 규칙을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            RuleComparisonHeader(detail: detail)
            if detail.changedArticles.isEmpty {
                InfoBanner(message: "이번 버전에서 비교할 조항이 없어요.", style: .muted)
            }
            ForEach(detail.changedArticles) { article in
                RuleChangedArticleCard(article: article, previousVersion: detail.previousVersion, version: detail.rule.version)
            }
            RuleUnchangedArticlesCard(articles: detail.unchangedArticles)
            InfoBanner(message: "바뀐 조항만 모아 보여줘요. 읽음 확인은 결재 완료가 아니에요.")
            actions(ruleId: detail.rule.id)
        }
    }

    private func actions(ruleId: Int) -> some View {
        VStack(spacing: Spacing.sm) {
            Button("전체 본문 보기") { onNavigate(.ruleDetail(id: ruleId)) }
                .buttonStyle(.tsSecondary)
            Button(viewModel.isAcknowledged ? viewModel.readingText : "개정 내용 읽음 확인") {
                Task { await viewModel.acknowledge() }
            }
            .buttonStyle(.tsPrimaryLarge)
            .disabled(viewModel.isAcknowledged || viewModel.isAcknowledging)
        }
        .padding(.top, Spacing.sm)
    }
}

#Preview {
    NavigationStack {
        RuleComparisonView(viewModel: DIContainer.preview().makeRuleDetailViewModel(ruleId: 1), onNavigate: { _ in })
    }
}
