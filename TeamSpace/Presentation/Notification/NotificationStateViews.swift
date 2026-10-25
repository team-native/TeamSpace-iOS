import SwiftUI

/// 02-4 · 02-5 칩 아래 "미확인 N · 확인 M"
struct NotificationReadSummary: View {
    let unread: Int
    let read: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            StatusBadge(title: "미확인 \(unread)", tone: unread > 0 ? .primary : .positive)
            StatusBadge(title: "확인 \(read)", tone: .neutral)
        }
    }
}

/// 02-5 새 알림을 모두 확인했어요
struct AllCaughtUpCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IconTile(icon: .checkCircle, iconSize: .xxl, tileSize: 52, tint: .tsPositive, background: .tsPositiveSoft, isCircle: true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("새 알림을 모두 확인했어요")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Text("이전 알림과 남아 있는 업무는 아래에서\n언제든 다시 확인할 수 있어요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            InfoBanner(
                message: "알림을 읽었다고 결재가 완료되지는 않아요. 처리할 요청은 받은 결재에서 계속 확인해 주세요.",
                icon: .infoCircle,
                style: .muted
            )
        }
        .tsCard()
    }
}

/// 알림 목록 맨 아래 안내 (02-3 · 02-4)
struct NotificationReadNotice: View {
    let filter: NotificationFilter

    var body: some View {
        InfoBanner(message: message, icon: .infoCircle, style: .muted)
    }

    private var message: String {
        switch filter {
        case .rule:
            return "알림 확인과 중요 규칙의 ‘읽음 확인’은 구분돼요. 읽음 확인은 결재 승인이나 업무 완료가 아니에요."
        default:
            return "알림 읽음은 업무 완료나 결재 승인이 아니에요. 처리할 요청은 받은 결재에서 확인해 주세요."
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        NotificationReadSummary(unread: 0, read: 3)
        AllCaughtUpCard()
        NotificationReadNotice(filter: .rule)
    }
    .padding()
    .background(Color.tsBackground)
}
