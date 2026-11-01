import SwiftUI

/// 이메일 · 비밀번호 입력, 로그인 상태 유지, 비밀번호 찾기, 오류 메시지
struct LoginFormSection: View {
    @Bindable var viewModel: LoginViewModel
    var isEmailFocused: FocusState<Bool>.Binding
    var isPasswordFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onFindPassword: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            TSTextField(
                label: "이메일",
                placeholder: "name@native.team",
                text: $viewModel.email,
                icon: .mail,
                hasError: viewModel.hasFieldError,
                keyboardType: .emailAddress,
                textContentType: .username,
                submitLabel: .next,
                focus: isEmailFocused,
                onSubmit: { isPasswordFocused.wrappedValue = true }
            )
            TSTextField(
                label: "비밀번호",
                placeholder: "비밀번호를 입력하세요",
                text: $viewModel.password,
                isSecure: true,
                hasError: viewModel.hasFieldError,
                textContentType: .password,
                submitLabel: .go,
                focus: isPasswordFocused,
                onSubmit: onSubmit
            )
            optionsRow
                .padding(.top, Spacing.xxs)
            if let errorMessage = viewModel.errorMessage {
                LoginErrorMessage(message: errorMessage)
            }
        }
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private var optionsRow: some View {
        HStack {
            Toggle(isOn: $viewModel.keepSignedIn) {
                Text("로그인 상태 유지")
            }
            .toggleStyle(CheckboxToggleStyle())
            Spacer()
            Button("비밀번호 찾기", action: onFindPassword)
                .tsFont(.footnoteMedium)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

private struct LoginErrorMessage: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TSIcon.info.image.tsIconSize(.md)
            Text(message).tsFont(.footnoteMedium)
        }
        .foregroundStyle(Color.tsNegative)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("오류: \(message)")
    }
}

/// 하단 고정 영역 — 키보드가 올라오면 함께 올라갑니다.
struct LoginBottomActions: View {
    let isEnabled: Bool
    let isLoading: Bool
    let onLogin: () -> Void
    let onRequestAccount: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Button(action: onLogin) {
                if isLoading {
                    ProgressView()
                        .tint(Color.tsOnPrimary)
                        .accessibilityLabel("로그인 중")
                } else {
                    Text("로그인")
                }
            }
            .buttonStyle(.tsPrimaryLarge)
            .disabled(!isEnabled)

            Button(action: onRequestAccount) {
                HStack(spacing: Spacing.xxs) {
                    Text("계정이 없으신가요?")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                    Text("인하우스 계정 요청하기")
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm + Spacing.xxxs)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.tsSurface)
    }
}

#Preview {
    VStack {
        Spacer()
        LoginBottomActions(isEnabled: true, isLoading: false, onLogin: {}, onRequestAccount: {})
        LoginBottomActions(isEnabled: false, isLoading: true, onLogin: {}, onRequestAccount: {})
    }
}
