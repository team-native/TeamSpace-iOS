import SwiftUI

/// 프로젝트 수정 — 상세를 불러와 작성 화면을 기존 내용으로 채워 열어요. (PATCH /admin/projects/{id})
struct ProjectEditView: View {
    @State private var viewModel: ProjectDetailViewModel
    private let container: DIContainer
    private let user: AuthUser

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectDetailViewModel, container: DIContainer, user: AuthUser) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.user = user
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail, user.can(.registerProjects) {
                ProjectComposeView(viewModel: container.makeProjectComposeViewModel(user: user, editing: detail.project))
            } else {
                placeholder
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TSNavigationBar(title: "프로젝트 수정", onBack: { dismiss() })
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
                InfoBanner(message: "프로젝트는 관리자만 고칠 수 있어요.", icon: .infoCircle, style: .muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
    }
}
