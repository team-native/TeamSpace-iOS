import SwiftUI

/// Figma `search` — 흰 배경 r14 검색창
struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            TSIcon.search.sized(.base)
                .foregroundStyle(Color.tsInk3)
            TextField(placeholder, text: $text)
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
    }
}

#Preview {
    SearchField(placeholder: "이름, 부서, 역할로 검색", text: .constant(""))
        .padding()
        .background(Color.tsBackground)
}
