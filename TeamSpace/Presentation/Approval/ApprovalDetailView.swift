import SwiftUI

/// 05-3 내 결재 상세 · 05-4 받은 결재 상세 (검토)
struct ApprovalDetailView: View {
    @State private var viewModel: ApprovalDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ApprovalDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
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
            TSNavigationBar(title: viewModel.detail?.isMine == false ? "결재 검토" : "결재 상세", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay { dialogOverlay }
        .animation(.easeInOut(duration: 0.2), value: viewModel.dialog)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didWithdraw) { _, didWithdraw in
            if didWithdraw { dismiss() }
        }
        .modifier(ApprovalDetailAlerts(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        case .empty, .forbidden:
            InfoBanner(message: "이 결재를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            if detail.isMine {
                MyApprovalDetailContent(detail: detail)
            } else {
                ReviewApprovalContent(detail: detail, meta: viewModel.reviewMeta, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let detail = viewModel.detail {
            if detail.canDecide {
                DualButtonBar(
                    leading: ("반려", { viewModel.isRejectAlertPresented = true }),
                    trailing: ("승인하기", { viewModel.dialog = .approveConfirm }),
                    isLeadingDestructive: true,
                    isDisabled: viewModel.isProcessing
                )
            } else if detail.canEdit {
                DualButtonBar(
                    leading: ("요청 취소", { viewModel.isWithdrawConfirmPresented = true }),
                    trailing: ("수정하기", { onNavigate(.comingSoon(title: "결재 수정")) }),
                    isLeadingDestructive: false,
                    isDisabled: viewModel.isProcessing
                )
            }
        }
    }

    @ViewBuilder
    private var dialogOverlay: some View {
        if let dialog = viewModel.dialog, let detail = viewModel.detail {
            switch dialog {
            case .approveConfirm:
                ApproveConfirmDialog(
                    nextApprover: detail.nextApprover,
                    isProcessing: viewModel.isProcessing,
                    onApprove: { Task { await viewModel.approve() } },
                    onCancel: { viewModel.dialog = nil }
                )
            case .completed(let decision):
                DecisionCompletedDialog(decision: decision, requesterName: detail.item.requesterName) {
                    viewModel.dialog = nil
                    dismiss()
                }
            }
        }
    }
}

/// 05-8 반려 사유 · 요청 취소 확인 · 토스트
private struct ApprovalDetailAlerts: ViewModifier {
    @Bindable var viewModel: ApprovalDetailViewModel

    func body(content: Content) -> some View {
        content
            .alert("반려 사유", isPresented: $viewModel.isRejectAlertPresented) {
                TextField("예) 예산 초과, 정보 부족", text: $viewModel.rejectReason)
                Button("취소", role: .cancel) { viewModel.rejectReason = "" }
                Button("반려") { Task { await viewModel.reject() } }
            } message: {
                Text("요청자에게 사유가 그대로 전달돼요.")
            }
            .confirmationDialog("결재 요청을 취소할까요?", isPresented: $viewModel.isWithdrawConfirmPresented, titleVisibility: .visible) {
                Button("요청 취소", role: .destructive) { Task { await viewModel.withdraw() } }
                Button("닫기", role: .cancel) {}
            } message: {
                Text("취소하면 작성 중 상태로 돌아가요.")
            }
            .alert(viewModel.toastMessage ?? "", isPresented: toastBinding) {
                Button("확인", role: .cancel) {}
            }
    }

    private var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )
    }
}

#Preview("05-3 내 결재") {
    NavigationStack {
        ApprovalDetailView(viewModel: DIContainer.preview().makeApprovalDetailViewModel(documentId: 1), onNavigate: { _ in })
    }
}

#Preview("05-4 받은 결재") {
    NavigationStack {
        ApprovalDetailView(viewModel: DIContainer.preview().makeApprovalDetailViewModel(documentId: 11), onNavigate: { _ in })
    }
}
