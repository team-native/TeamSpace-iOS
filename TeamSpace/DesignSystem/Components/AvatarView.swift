import SwiftUI

extension EnvironmentValues {
    /// 프로필 사진 상대 경로(`/people/{id}/photo`)를 풀 서버 주소 — 앱 시작 때 넣어요.
    @Entry var photoBaseURL: URL?
}

/// 미모티콘 자리 — 프로필 사진이 있으면 사진, 없거나 못 받으면 기본 얼굴
struct AvatarView: View {
    var size: CGFloat = 36
    var photo: ProfilePhoto?

    @Environment(\.photoBaseURL) private var baseURL

    var body: some View {
        ZStack {
            placeholder
            if let url = photo?.url(relativeTo: baseURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
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
    }
}

#Preview {
    AvatarView()
}
