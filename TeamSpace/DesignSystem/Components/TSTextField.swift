import SwiftUI

/// Figma `field/~` — 라벨 + 회색 입력 박스 + 우측 아이콘
struct TSTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: TSIcon?
    var isSecure: Bool = false
    var hasError: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var submitLabel: SubmitLabel = .done
    var focus: FocusState<Bool>.Binding?
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            HStack(spacing: Spacing.sm) {
                inputField
                    .tsFont(.body)
                    .foregroundStyle(Color.tsInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .submitLabel(submitLabel)
                    .onSubmit(onSubmit)
                    .modifier(OptionalFocus(focus: focus))
                trailingIcon
            }
            .padding(.horizontal, Spacing.lg)
            .frame(height: 52)
            .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(hasError ? Color.tsNegative : Color.clear, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var inputField: some View {
        if isSecure && !isRevealed {
            SecureField(placeholder, text: $text, prompt: prompt)
        } else {
            TextField(placeholder, text: $text, prompt: prompt)
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Color.tsInk3)
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if isSecure {
            Button(action: toggleReveal) {
                (isRevealed ? TSIcon.eyeSlash : TSIcon.eye).image
                    .tsIconSize(.lg)
                    .foregroundStyle(Color.tsInk3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "비밀번호 숨기기" : "비밀번호 보기")
        } else if let icon {
            icon.image
                .tsIconSize(.lg)
                .foregroundStyle(Color.tsInk3)
                .accessibilityHidden(true)
        }
    }

    /// 보기/숨기기로 입력창이 바뀌어도 키보드가 내려가지 않도록 포커스를 유지합니다.
    private func toggleReveal() {
        let wasFocused = focus?.wrappedValue ?? false
        isRevealed.toggle()
        if wasFocused, let focus {
            focus.wrappedValue = true
        }
    }
}

private struct OptionalFocus: ViewModifier {
    let focus: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        if let focus {
            content.focused(focus)
        } else {
            content
        }
    }
}

private struct TSTextFieldPreview: View {
    @State private var email = ""
    @State private var password = "abc12345"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            TSTextField(label: "이메일", placeholder: "name@native.team", text: $email, icon: .mail)
            TSTextField(label: "비밀번호", placeholder: "비밀번호를 입력하세요", text: $password, isSecure: true)
            TSTextField(label: "오류 상태", placeholder: "입력", text: $email, hasError: true)
        }
        .padding()
    }
}

#Preview {
    TSTextFieldPreview()
}
