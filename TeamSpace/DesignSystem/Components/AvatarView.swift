import SwiftUI

/// Figma `Avatar / Memoji` — 미모티콘 자리 (이미지가 없으면 그라디언트 + 사람 모양)
struct AvatarView: View {
    var size: CGFloat = 36

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.tsAvatarStart, Color.tsAvatarEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(Color.tsOnPrimary)
                    .offset(y: size * 0.08)
            }
            .clipShape(Circle())
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    AvatarView()
}
