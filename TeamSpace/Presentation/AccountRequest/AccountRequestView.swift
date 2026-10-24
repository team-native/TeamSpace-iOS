import SwiftUI

/// 01-2 인하우스 계정 요청
struct AccountRequestView: View {
    @State private var viewModel: AccountRequestViewModel
    private let onCompleted: (AccountRequestReceipt) -> Void
    private let onBackToLogin: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: AccountRequestViewModel,
        onCompleted: @escaping (AccountRequestReceipt) -> Void,
        onBackToLogin: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onCompleted = onCompleted
        self.onBackToLogin = onBackToLogin
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CircleIconButton(icon: .chevronLeft, accessibilityLabel: "뒤로") { dismiss() }
                    .padding(.bottom, Spacing.xxl)
                AccountRequestHeader()
                    .padding(.bottom, Spacing.xxxl)
                AccountRequestFormSection(viewModel: viewModel, onSubmit: submit)
                    .padding(.bottom, Spacing.xl)
                InfoBanner(
                    message: "요청 정보는 운영진(NativeOps)만 확인해요. 승인되면 메일과 알림으로 알려드려요.",
                    icon: .shield
                )
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AccountRequestBottomActions(
                isEnabled: viewModel.canSubmit,
                isLoading: viewModel.isSubmitting,
                errorMessage: viewModel.errorMessage,
                onSubmit: submit,
                onBackToLogin: onBackToLogin
            )
        }
        .background(Color.tsSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.form) { _, _ in viewModel.clearError() }
    }

    private func submit() {
        Task {
            if let receipt = await viewModel.submit() {
                onCompleted(receipt)
            }
        }
    }
}

private struct AccountRequestHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            HStack(spacing: Spacing.xs) {
                Circle().fill(Color.tsPrimary).frame(width: 6, height: 6)
                Text("ACCOUNT REQUEST")
                    .tsFont(.caption2Bold)
                    .foregroundStyle(Color.tsPrimary)
            }
            .padding(.bottom, Spacing.xxs)
            Text("인하우스 계정을\n요청할게요.")
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
            Text("운영진이 확인한 뒤 접근 권한을 열어드려요.")
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk2)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 하단 고정 — 오류 문구 · 계정 요청하기 · 로그인 링크
private struct AccountRequestBottomActions: View {
    let isEnabled: Bool
    let isLoading: Bool
    let errorMessage: String?
    let onSubmit: () -> Void
    let onBackToLogin: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if let errorMessage {
                Label(errorMessage, systemImage: TSIcon.info.rawValue)
                    .tsFont(.footnoteMedium)
                    .foregroundStyle(Color.tsNegative)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("오류: \(errorMessage)")
            }
            Button(action: onSubmit) {
                if isLoading {
                    ProgressView().tint(Color.tsOnPrimary).accessibilityLabel("요청 중")
                } else {
                    Text("계정 요청하기")
                }
            }
            .buttonStyle(.tsPrimaryLarge)
            .disabled(!isEnabled)

            Button(action: onBackToLogin) {
                HStack(spacing: Spacing.xxs) {
                    Text("이미 계정이 있나요?").tsFont(.callout).foregroundStyle(Color.tsInk3)
                    Text("로그인").tsFont(.calloutBold).foregroundStyle(Color.tsPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm + Spacing.xxxs)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.tsSurface)
    }
}

#Preview {
    NavigationStack {
        AccountRequestView(
            viewModel: DIContainer.preview().makeAccountRequestViewModel(),
            onCompleted: { _ in },
            onBackToLogin: {}
        )
    }
}
