import SwiftUI

/// 01-1 로그인
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var passwordResetViewModel: PasswordResetViewModel
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    private let onLoginSucceeded: (AuthUser) -> Void
    private let onRequestAccount: () -> Void

    init(
        viewModel: LoginViewModel,
        passwordResetViewModel: PasswordResetViewModel,
        onLoginSucceeded: @escaping (AuthUser) -> Void = { _ in },
        onRequestAccount: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        _passwordResetViewModel = State(initialValue: passwordResetViewModel)
        self.onLoginSucceeded = onLoginSucceeded
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
                    onFindPassword: findPassword
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
        .passwordResetAlert(passwordResetViewModel)
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

    private func findPassword() {
        dismissKeyboard()
        passwordResetViewModel.present(prefilledEmail: viewModel.email)
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
    let container = DIContainer.preview()
    return LoginView(
        viewModel: container.makeLoginViewModel(),
        passwordResetViewModel: container.makePasswordResetViewModel()
    )
}

#Preview("다크 모드") {
    let container = DIContainer.preview()
    return LoginView(
        viewModel: container.makeLoginViewModel(),
        passwordResetViewModel: container.makePasswordResetViewModel()
    )
    .preferredColorScheme(.dark)
}
