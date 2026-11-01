import SwiftUI

/// 01-1 로그인
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    private let onLoginSucceeded: (AuthUser) -> Void
    private let onFindPassword: () -> Void
    private let onRequestAccount: () -> Void

    /// 비밀번호 찾기(01-4) · 계정 요청(01-2)은 다음 이슈에서 연결합니다.
    init(
        viewModel: LoginViewModel,
        onLoginSucceeded: @escaping (AuthUser) -> Void = { _ in },
        onFindPassword: @escaping () -> Void = {},
        onRequestAccount: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onLoginSucceeded = onLoginSucceeded
        self.onFindPassword = onFindPassword
        self.onRequestAccount = onRequestAccount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandLogo()
                    .padding(.bottom, Spacing.xxxl + Spacing.md)
                LoginHeader()
                    .padding(.bottom, Spacing.xxxl + Spacing.sm)
                LoginFormSection(
                    viewModel: viewModel,
                    isEmailFocused: $isEmailFocused,
                    isPasswordFocused: $isPasswordFocused,
                    onSubmit: submit,
                    onFindPassword: onFindPassword
                )
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // 빈 곳을 누르면 키보드를 내립니다.
                Color.tsSurface
                    .contentShape(Rectangle())
                        }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LoginBottomActions(
                isEnabled: viewModel.canSubmit,
                isLoading: viewModel.isLoading,
                onLogin: submit,
                onRequestAccount: onRequestAccount
            )
        }
        .background(Color.tsSurface.ignoresSafeArea())
        .onChange(of: viewModel.email) { _, _ in viewModel.clearError() }
        .onChange(of: viewModel.password) { _, _ in viewModel.clearError() }
    }

    private func submit() {
        dismissKeyboard()
        Task {
            if let user = await viewModel.login() {
                onLoginSucceeded(user)
            }
        }
    }

    private func dismissKeyboard() {
        isEmailFocused = false
        isPasswordFocused = false
    }
}

private struct LoginHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            Text("다시 만나서 반가워요.")
                .tsFont(.title1)
                .foregroundStyle(Color.tsInk)
            Text("승인된 \(BrandLogo.brandName) 계정으로 로그인해 주세요.")
                .tsFont(.body)
                .foregroundStyle(Color.tsInk2)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("기본") {
    LoginView(viewModel: DIContainer.preview().makeLoginViewModel())
}

#Preview("다크 모드") {
    LoginView(viewModel: DIContainer.preview().makeLoginViewModel())
        .preferredColorScheme(.dark)
}
