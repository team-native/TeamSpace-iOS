import SwiftUI

/// 알림 카드 — 안 읽은 결재 요청은 '바로 검토 · 나중에' 버튼이 있는 큰 카드
struct NotificationCard: View {
    let notification: AppNotification
    let onOpen: () -> Void
    let onReview: () -> Void
    let onLater: () -> Void

    private var isActionable: Bool {
        notification.type == .approval && !notification.isRead
    }

    var body: some View {
        Group {
            if isActionable {
                actionableContent
            } else {
                Button(action: onOpen) { compactContent }
                    .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            if notification.isRead {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous).stroke(Color.tsLine, lineWidth: 1)
            }
        }
        .tsShadow(notification.isRead ? .none : .card)
        .accessibilityElement(children: .contain)
    }

    private var compactContent: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            NotificationTile(notification: notification)
            VStack(alignment: .leading, spacing: Spacing.compact) {
                NotificationMetaRow(notification: notification)
                titleText
                if let message = notification.message {
                    Text(message).tsFont(.footnote).foregroundStyle(Color.tsInk2)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var actionableContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            HStack(alignment: .center, spacing: Spacing.md) {
                NotificationTile(notification: notification)
                VStack(alignment: .leading, spacing: Spacing.compact) {
                    NotificationMetaRow(notification: notification)
                    titleText
                }
            }
            if let message = notification.message {
                Text(message).tsFont(.footnote).foregroundStyle(Color.tsInk2)
            }
            HStack(spacing: Spacing.sm) {
                Button("바로 검토", action: onReview)
                    .buttonStyle(.ts(.primary, size: .small, fullWidth: false))
                Button("나중에", action: onLater)
                    .buttonStyle(.ts(.secondary, size: .small, fullWidth: false))
            }
        }
    }

    private var titleText: some View {
        Text(notification.title)
            .tsFont(.bodyBold)
            .foregroundStyle(Color.tsInk)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 왼쪽 아이콘 타일 — 읽은 알림은 회색
private struct NotificationTile: View {
    let notification: AppNotification

    var body: some View {
        notification.type.icon.sized(.xl)
            .foregroundStyle(notification.isRead ? Color.tsInk2 : notification.type.tint)
            .frame(width: 44, height: 44)
            .background(
                notification.isRead ? Color.tsSurface2 : notification.type.tileBackground,
                in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// 출처 · 시간 · 안 읽음 점
private struct NotificationMetaRow: View {
    let notification: AppNotification

    var body: some View {
        HStack {
            Text(notification.type.sourceLabel)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            Spacer()
            HStack(spacing: Spacing.xxs + 1) {
                Text(TSFormat.relative(notification.createdAt))
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                if !notification.isRead {
                    Circle()
                        .fill(Color.tsNegative)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel("읽지 않음")
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NotificationCard(
            notification: AppNotification(
                id: 1, type: .approval, title: "새 결재 요청이 도착했어요",
                message: "이시우 님이 Book-on 프로젝트 인력 지원(iOS 1명)을 요청했어요.",
                deepLink: nil, isRead: false, createdAt: Date()
            ),
            onOpen: {}, onReview: {}, onLater: {}
        )
        NotificationCard(
            notification: AppNotification(
                id: 2, type: .rule, title: "프로젝트 운영 원칙이 개정됐어요",
                message: "시행 10월 20일 · NativeOps · 변경 3건",
                deepLink: nil, isRead: true, createdAt: Date().addingTimeInterval(-86_400 * 3)
            ),
            onOpen: {}, onReview: {}, onLater: {}
        )
    }
    .padding()
    .background(Color.tsBackground)
}
