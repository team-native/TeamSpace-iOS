import SwiftUI

/// 이름 · 이메일 · 소속 부서(01-5 메뉴) · 비밀번호 · 선택 정보(전공 · 기수 · 하고 싶은 말)
struct AccountRequestFormSection: View {
    @Bindable var viewModel: AccountRequestViewModel
    let onSubmit: () -> Void

    @FocusState private var isNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isMajorFocused: Bool
    @FocusState private var isCohortFocused: Bool

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
            DepartmentSelectField(selection: viewModel.form.department) {
                isNameFocused = false
                isEmailFocused = false
                isPasswordFocused = false
                viewModel.isDepartmentPickerPresented = true
            }
            passwordField
            optionalFields
        }
        .disabled(viewModel.isSubmitting)
    }

    /// Figma 01-2 수정안 — 전공 · 기수 한 줄, 하고 싶은 말 여러 줄
    private var optionalFields: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
                TSTextField(
                    label: "전공 (선택)",
                    placeholder: "예: 스마트IoT과",
                    text: $viewModel.form.major,
                    submitLabel: .next,
                    focus: $isMajorFocused,
                    onSubmit: { isCohortFocused = true }
                )
                TSTextField(
                    label: "기수 (선택)",
                    placeholder: "예: 9기",
                    text: $viewModel.form.cohort,
                    submitLabel: .next,
                    focus: $isCohortFocused,
                    onSubmit: { isCohortFocused = false }
                )
            }
            messageField
        }
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("하고 싶은 말 (선택)")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            TextEditor(text: Binding(get: { viewModel.form.message }, set: { viewModel.updateMessage($0) }))
                .tsFont(.body)
                .foregroundStyle(Color.tsInk)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(alignment: .topLeading) {
                    if viewModel.form.message.isEmpty {
                        Text("참여하고 싶은 프로젝트나 운영진에게 전할 말을 적어 주세요.")
                            .tsFont(.body)
                            .foregroundStyle(Color.tsInk3)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md + Spacing.xxxs)
                            .accessibilityHidden(true)
                    }
                }
                .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityLabel("하고 싶은 말, 선택")
                .accessibilityValue(viewModel.messageCountText)
            Text(viewModel.messageCountText)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
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
