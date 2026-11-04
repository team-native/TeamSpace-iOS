import SwiftUI
import UIKit

/// 04-2 수주 상세
struct ContractDetailView: View {
    @State private var viewModel: ContractDetailViewModel
    private let onNavigate: (AppRoute) -> Void
    /// FA · Admin 은 수금 내역을 고칠 수 있어요.
    private let canEdit: Bool

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractDetailViewModel, canEdit: Bool = false, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.canEdit = canEdit
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
                if canEdit, viewModel.state.value != nil {
                    CircleIconButton(icon: .pencil, accessibilityLabel: "수금 수정", background: .tsSurface, hasBorder: true) {
                        onNavigate(.receiptEdit(id: viewModel.contractId))
                    }
                }
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
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            AccessDeniedView(
                onInquire: { onNavigate(.inquiryCompose(.accessRequest)) },
                onBack: { dismiss() }
            )
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
        case .loaded(let detail):
            ContractHeader(detail: detail)
            ContractAmountCard(amount: detail.contract.amount, caption: viewModel.amountCaption(detail))
            ContractStepsSection(steps: detail.steps)
            ContractPoolSection(pools: detail.pools)
            ContractRelatedSection(detail: detail) {
                onNavigate(.comingSoon(title: "문서함"))
            }
            if canEdit {
                Button(detail.info == nil ? "계약 정보 등록" : "계약 정보 수정") {
                    onNavigate(.contractInfoEdit(receiptId: viewModel.contractId))
                }
                .buttonStyle(.tsSecondary)
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
