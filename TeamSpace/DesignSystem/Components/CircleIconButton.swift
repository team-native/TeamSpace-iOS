import SwiftUI

/// Figma `iconbtn/~` — 원형 아이콘 버튼 (뒤로가기 등)
struct CircleIconButton: View {
    let icon: TSIcon
    let accessibilityLabel: String
    var size: CGFloat = 36
    var background: Color = .tsBackground
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .tsIconSize(.lg, weight: .semibold)
                .foregroundStyle(Color.tsInk)
                .frame(width: size, height: size)
                .background(background, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    CircleIconButton(icon: .chevronLeft, accessibilityLabel: "뒤로") {}
        .padding()
}
