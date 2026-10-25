import SwiftUI

/// 02-4 제도 · 규칙 알림 카드 — 시행일 + 전후 비교 · 읽음 확인
struct RuleNotificationCard: View {
    let notification: AppNotification
    let onCompare: () -> Void
    let onConfirmRead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                StatusBadge(
                    title: notification.isRead ? "확인" : "미확인 · 중요",
                    tone: notification.isRead ? .neutral : .primary
                )
                Spacer(minLength: 0)
                Text("\(TSFormat.relative(notification.createdAt)) · NativeOps")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(notification.title)
                    .tsFont(notification.isRead ? .bodyBold : .headline)
                    .foregroundStyle(Color.tsInk)
                if let message = notification.message {
                    Text(message)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let effectiveAt = notification.effectiveAt {
                StatusBadge(title: effectiveLabel(effectiveAt), tone: .violet)
            }
            actions
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .tsShadow(notification.isRead ? .none : .card)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var actions: some View {
        if notification.isRead {
            Button("규칙 본문 보기", action: onCompare)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsPrimary)
                .buttonStyle(.plain)
        } else {
            VStack(spacing: Spacing.sm) {
                Button("변경 요약 · 전후 비교", action: onCompare)
                    .buttonStyle(.ts(.primary, size: .medium))
                Button("중요 규칙 읽음 확인", action: onConfirmRead)
                    .buttonStyle(.ts(.secondary, size: .medium))
            }
        }
    }

    /// 시행 예정 · 2026.10.20 / 시행 중 · 2026.10.01부터
    private func effectiveLabel(_ date: Date) -> String {
        let text = Self.dateFormatter.string(from: date)
        return date > Date() ? "시행 예정 · \(text)" : "시행 중 · \(text)부터"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

/// 02-3 내 문의 답변 도착 카드 — 작성자 본인만 받는 알림
struct InquiryAnswerCard: View {
    let notification: AppNotification
    let onOpenAnswer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                if !notification.isRead {
                    StatusBadge(title: "● 안읽음", tone: .primaryFilled)
                }
                StatusBadge(title: "문의 답변 · 작성자만", tone: .primary)
            }
            Text(notification.title)
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            Text("답변 \(TSFormat.relative(notification.createdAt)) · NativeOps")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk2)
            if let message = notification.message {
                Text("“\(message)”")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            Button("내 문의의 공식 답변 보기", action: onOpenAnswer)
                .buttonStyle(.ts(.primary, size: .medium))
            Text("작성자 본인만 받는 알림이에요. 팀 게시판이나 다른 구성원에게 공개되지 않아요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(notification.isRead ? Color.tsLine : Color.tsPrimary.opacity(0.3), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            RuleNotificationCard(
                notification: AppNotification(
                    id: 1, type: .rule, title: "프로젝트 운영 원칙이 개정됐어요",
                    message: "제안 검토 기한이 3주에서 2주로 바뀌어요.", deepLink: nil, isRead: false,
                    createdAt: Date(), effectiveAt: Date().addingTimeInterval(86_400 * 5)
                ),
                onCompare: {}, onConfirmRead: {}
            )
            InquiryAnswerCard(
                notification: AppNotification(
                    id: 2, type: .inquiryAnswer, title: "내 문의에 답변이 도착했어요",
                    message: "제출 기한을 다음 주 금요일까지 연장했어요.", deepLink: nil, isRead: false, createdAt: Date()
                ),
                onOpenAnswer: {}
            )
        }
        .padding()
    }
    .background(Color.tsBackground)
}
