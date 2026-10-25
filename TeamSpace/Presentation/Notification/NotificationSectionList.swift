import SwiftUI

/// 오늘 / 이번 주 묶음 + 알림 카드
struct NotificationSectionList: View {
    let sections: [NotificationSection]
    let onOpen: (AppNotification) -> Void
    let onReview: (AppNotification) -> Void
    /// 규칙 전후 비교 · 문의 답변처럼 다른 화면으로 이동
    let onOpenTarget: (AppNotification) -> Void

    var body: some View {
        if sections.isEmpty {
            NotificationEmptyView(message: "이 분류에는 도착한 알림이 없어요.")
        } else {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
                    Text(section.title)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk3)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(section.items) { notification in
                        card(for: notification)
                    }
                }
            }
        }
    }
}

extension NotificationSectionList {
    /// 알림 종류에 맞는 카드 (02-3 문의 답변 · 02-4 규칙 · 그 외)
    @ViewBuilder
    fileprivate func card(for notification: AppNotification) -> some View {
        switch notification.type {
        case .rule:
            RuleNotificationCard(
                notification: notification,
                onCompare: { onOpenTarget(notification) },
                onConfirmRead: { onOpen(notification) }
            )
        case .inquiryAnswer:
            InquiryAnswerCard(notification: notification, onOpenAnswer: { onOpenTarget(notification) })
        default:
            NotificationCard(
                notification: notification,
                onOpen: { onOpen(notification) },
                onReview: { onReview(notification) },
                onLater: { onOpen(notification) }
            )
        }
    }
}

/// 알림이 없을 때
struct NotificationEmptyView: View {
    var message: String = "새 결재 요청이나 일정 변경이 생기면 바로 알려드릴게요."

    var body: some View {
        VStack(spacing: Spacing.md) {
            TSIcon.bell.sized(.hero)
                .foregroundStyle(Color.tsInk3)
            Text("도착한 알림이 없어요")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl * 2)
    }
}

/// 불러오기 실패 — 재시도 버튼 제공
struct NotificationErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("알림을 불러오지 못했어요")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
            Button("다시 시도", action: onRetry)
                .buttonStyle(.ts(.secondary, size: .small, fullWidth: false))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl * 2)
    }
}
