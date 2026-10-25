import SwiftUI

/// Figma `search` — 흰 배경 r14 검색창
struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    /// 화면이 열리면 바로 키보드를 올려요. (06-2 문서 검색)
    var autoFocus = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            TSIcon.search.sized(.base)
                .foregroundStyle(Color.tsInk3)
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .tsIconSize(.base)
                        .foregroundStyle(Color.tsInk3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, Spacing.md + Spacing.xxxs)
        .frame(height: 46)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .task {
            guard autoFocus else { return }
            // 화면 전환 애니메이션이 끝난 뒤에 올려야 키보드가 잘 떠요.
            try? await Task.sleep(nanoseconds: 350_000_000)
            isFocused = true
        }
    }
}

#Preview {
    SearchField(placeholder: "이름, 부서, 역할로 검색", text: .constant(""))
        .padding()
        .background(Color.tsBackground)
}
