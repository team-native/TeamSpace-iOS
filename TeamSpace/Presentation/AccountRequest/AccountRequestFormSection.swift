import SwiftUI

/// 이름 · 이메일 · 소속 부서(01-5 메뉴) · 비밀번호
struct AccountRequestFormSection: View {
    @Bindable var viewModel: AccountRequestViewModel
    let onSubmit: () -> Void

    @FocusState private var isNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            TSTextField(
                label: "이름",
                placeholder: "이름을 입력해 주세요",
                text: $viewModel.form.name,
                textContentType: .name,
                submitLabel: .next,
                focus: $isNameFocused,
                onSubmit: { isEmailFocused = true }
            )
            emailField
            DepartmentMenuField(
                departments: viewModel.departments,
                selection: viewModel.form.department,
                onSelect: { viewModel.select($0) }
            )
            passwordField
        }
        .disabled(viewModel.isSubmitting)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TSTextField(
                label: "학교 / 업무 이메일",
                placeholder: "s00000@gsm.hs.kr",
                text: $viewModel.form.email,
                icon: .mail,
                hasError: viewModel.showsEmailHint,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                submitLabel: .next,
                focus: $isEmailFocused,
                onSubmit: { isEmailFocused = false }
            )
            if viewModel.showsEmailHint {
                Text("이메일 형식을 확인해 주세요.")
                    .tsFont(.captionMedium)
                    .foregroundStyle(Color.tsNegative)
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TSTextField(
                label: "비밀번호",
                placeholder: "영문 · 숫자 포함 8자 이상",
                text: $viewModel.form.password,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .done,
                focus: $isPasswordFocused,
                onSubmit: onSubmit
            )
            PasswordRuleLabel(state: viewModel.passwordRuleState)
        }
    }
}

private struct PasswordRuleLabel: View {
    let state: PasswordRuleState

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TSIcon.check.image.tsIconSize(.xs, weight: .bold)
            Text("영문 · 숫자 포함 8자 이상").tsFont(.captionMedium)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }

    private var color: Color {
        switch state {
        case .idle: return .tsInk3
        case .valid: return .tsPositive
        case .invalid: return .tsNegative
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .idle: return ""
        case .valid: return "조건 충족"
        case .invalid: return "조건 미충족"
        }
    }
}
