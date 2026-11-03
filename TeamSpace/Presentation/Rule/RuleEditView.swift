import SwiftUI

/// 규칙 개정 — 규칙을 불러와 작성 화면을 기존 내용으로 채워 열어요. (POST /admin/docs)
struct RuleEditView: View {
    @State private var viewModel: RuleDetailViewModel
    private let container: DIContainer
    private let user: AuthUser

    @Environment(\.dismiss) private var dismiss

    init(viewModel: RuleDetailViewModel, container: DIContainer, user: AuthUser) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.user = user
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail, user.can(.manageDocs) {
                RuleComposeView(viewModel: container.makeRuleComposeViewModel(user: user, editing: detail))
            } else {
                placeholder
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TSNavigationBar(title: "규칙 개정", onBack: { dismiss() })
                            .padding(.horizontal, Spacing.screen)
                            .padding(.bottom, Spacing.sm)
                            .background(Color.tsBackground)
                    }
                    .background(Color.tsBackground.ignoresSafeArea())
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task { if viewModel.detail == nil { await viewModel.load() } }
    }

    @ViewBuilder
    private var placeholder: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
            case .failed(let error):
                ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
            case .empty, .forbidden, .loaded:
                InfoBanner(message: "규칙은 관리자만 개정할 수 있어요.", icon: .infoCircle, style: .muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
    }
}
