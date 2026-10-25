import SwiftUI
import UIKit

/// 04-2 수주 상세
struct ContractDetailView: View {
    @State private var viewModel: ContractDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "수주 상세", onBack: { dismiss() }) {
                CircleIconButton(icon: .link, accessibilityLabel: "수주 링크 복사", background: .tsSurface) {
                    UIPasteboard.general.string = viewModel.shareLink
                    viewModel.didCopyLink()
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .alert(viewModel.toastMessage ?? "", isPresented: toastBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        case .empty, .forbidden:
            InfoBanner(message: "이 수주 정보를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            ContractHeader(detail: detail)
            ContractAmountCard(amount: detail.contract.amount, caption: viewModel.amountCaption(detail))
            ContractStepsSection(steps: detail.steps)
            ContractPoolSection(pools: detail.pools)
            ContractRelatedSection(detail: detail) {
                onNavigate(.comingSoon(title: "문서함"))
            }
        }
    }

    private var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        ContractDetailView(viewModel: DIContainer.preview().makeContractDetailViewModel(contractId: 1), onNavigate: { _ in })
    }
}
