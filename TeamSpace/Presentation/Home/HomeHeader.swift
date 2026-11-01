import SwiftUI

/// 02-1 상단 — 로고 + 알림(배지) + 미모티콘
struct HomeHeader: View {
    let unreadCount: Int
    let onBell: () -> Void
    let onAvatar: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            BrandLogo()
            Spacer(minLength: 0)
            Button(action: onBell) {
                TSIcon.bell.sized(.lg)
                    .foregroundStyle(Color.tsInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tsSurface, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if unreadCount > 0 {
                            Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.tsOnPrimary)
                                .frame(minWidth: 14, minHeight: 14)
                                .background(Color.tsNegative, in: Capsule())
                                .offset(x: 2, y: -2)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(unreadCount > 0 ? "알림, 안 읽은 알림 \(unreadCount)개" : "알림")

            Button(action: onAvatar) {
                AvatarView()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("내 계정")
        }
        .frame(height: 44)
    }
}

/// 02-1 인사말
struct HomeGreeting: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.tsPrimary)
                    .frame(width: 5, height: 5)
                Text("NATIVE TEAMSPACE")
                    .tsFont(.micro)
                    .foregroundStyle(Color.tsInk2)
            }
            Text("Native의 일을\n한곳에서.")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack {
        HomeHeader(unreadCount: 3, onBell: {}, onAvatar: {})
        HomeGreeting(message: "옥물결 님, 오늘 확인할 일이 3건 있어요.")
    }
    .padding()
    .background(Color.tsBackground)
}
