import SwiftUI

/// 10-2 내 글 수정 — 글을 불러와 글쓰기 화면을 기존 내용으로 채워 열어요. (PATCH /posts/{id})
struct PostEditView: View {
    @State private var viewModel: PostDetailViewModel
    private let container: DIContainer
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostDetailViewModel, container: DIContainer, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.onNavigate = onNavigate
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail, viewModel.canEdit {
                PostComposeView(viewModel: container.makePostComposeViewModel(editing: detail), onNavigate: onNavigate)
            } else {
                placeholder
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TSNavigationBar(title: "글 수정", onBack: { dismiss() })
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
                InfoBanner(message: "내가 쓴 글만 고칠 수 있어요.", icon: .infoCircle, style: .muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
    }
}
