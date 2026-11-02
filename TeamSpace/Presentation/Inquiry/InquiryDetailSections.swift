import SwiftUI

/// 11-4 위 — 상태 · 제목 · 대상 · 접수일 · 익명
struct InquiryDetailHeader: View {
    let inquiry: InquirySummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            StatusBadge(status: inquiry.status, size: .small)
            Text(inquiry.title)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(inquiry.detailMetaText)
                Text("작성자인 나에게만 보이는 문의 상세")
            }
            .tsFont(.caption2)
            .foregroundStyle(Color.tsInk3)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 11-4 내가 보낸 내용
struct InquiryBodyCard: View {
    let text: String

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내가 보낸 내용")
            Text(text)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 11-4 처리 이력 — 단계 · 시각 · 메모
struct InquiryHistoryCard: View {
    let history: [InquiryHistory]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "처리 이력")
            ForEach(Array(history.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == history.count - 1 ? Color.tsPrimary : Color.tsInk3)
                            .frame(width: 8, height: 8)
                            .padding(.top, Spacing.xxs)
                        if index < history.count - 1 {
                            Rectangle().fill(Color.tsLine).frame(width: 1).frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(item.status.title)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsInk)
                        Text(item.detailText)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    .padding(.bottom, index < history.count - 1 ? Spacing.md : 0)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 11-4 공식 답변 / 11-7 반려 사유
struct InquiryReplyCard: View {
    let reply: InquiryReply
    let isRejection: Bool

    var body: some View {
        WorkspaceCard(background: isRejection ? .tsNegativeSoft : .tsPrimarySoft) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(isRejection ? "반려 사유" : "\(reply.department.title) 공식 답변")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(isRejection ? Color.tsNegative : Color.tsPrimary)
                Text("\(reply.department.title) · \(TSFormat.fullDate(reply.repliedAt)) \(TSFormat.time(reply.repliedAt))")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Text(reply.body)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 11-4 답변 뒤에 이어서 보낸 추가 메시지
struct InquiryFollowUpCard: View {
    let followUps: [InquiryFollowUp]

    var body: some View {
        WorkspaceCard {
            Text("추가 문의 \(followUps.count)")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            ForEach(Array(followUps.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("\(item.author) · \(TSFormat.fullDate(item.sentAt)) \(TSFormat.time(item.sentAt))")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                    Text(item.text)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 11-4 관련 규칙 · 11-7 관련 공지
struct InquiryReferenceCard: View {
    let reference: InquiryReference
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            Text(reference.caption)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            WorkspaceItemText(title: reference.title, meta: reference.summary)
            WorkspaceLinkRow(title: reference.linkTitle, action: onOpen)
        }
    }
}
