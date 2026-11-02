import SwiftUI

/// 05-3 결재 수정 · 07-5 이어서 작성 — 결재를 불러와 같은 종류 양식을 기존 내용으로 채워 열어요.
/// 저장 · 제출은 새 결재를 만들지 않고 같은 결재를 고쳐요. (PATCH /approvals/{id})
struct ApprovalEditView: View {
    @State private var viewModel: ApprovalDetailViewModel
    private let container: DIContainer
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ApprovalDetailViewModel, container: DIContainer, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.onNavigate = onNavigate
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail, detail.canEdit {
                ApprovalComposeView(container: container, onNavigate: onNavigate, editing: detail)
            } else {
                placeholder
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TSNavigationBar(title: "결재 수정", onBack: { dismiss() })
                            .padding(.horizontal, Spacing.screen)
                            .padding(.bottom, Spacing.sm)
                            .background(Color.tsBackground)
                    }
                    .background(Color.tsBackground.ignoresSafeArea())
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task { await viewModel.load() }
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
                InfoBanner(message: "작성 중이거나 반려된 내 결재만 고칠 수 있어요.", icon: .infoCircle, style: .muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
    }
}
