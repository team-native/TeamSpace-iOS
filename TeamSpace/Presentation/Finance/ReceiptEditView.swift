import SwiftUI

/// 수금 수정 — 수주 상세를 불러와 작성 화면을 기존 값으로 채워 열어요. (PATCH /admin/finance/receipts/{id})
struct ReceiptEditView: View {
    @State private var viewModel: ContractDetailViewModel
    private let container: DIContainer
    private let user: AuthUser

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractDetailViewModel, container: DIContainer, user: AuthUser) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.user = user
    }

    var body: some View {
        Group {
            if let detail = viewModel.state.value, user.can(.manageReceipts) {
                ReceiptComposeView(viewModel: container.makeReceiptComposeViewModel(user: user, editing: detail.contract))
            } else {
                placeholder
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TSNavigationBar(title: "수금 수정", onBack: { dismiss() })
                            .padding(.horizontal, Spacing.screen)
                            .padding(.bottom, Spacing.sm)
                            .background(Color.tsBackground)
                    }
                    .background(Color.tsBackground.ignoresSafeArea())
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task { if viewModel.state.value == nil { await viewModel.load() } }
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
                InfoBanner(message: "수금 내역은 FA · 관리자만 고칠 수 있어요.", icon: .infoCircle, style: .muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
    }
}
