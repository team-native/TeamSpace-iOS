import SwiftUI

/// 결재선
struct ApproverLineSection: View {
    let approvers: [Approver]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("결재선")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: 0) {
                ForEach(Array(approvers.enumerated()), id: \.element.id) { index, approver in
                    if index > 0 { TSDivider() }
                    HStack(spacing: Spacing.md) {
                        AvatarView(size: 36)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text("\(approver.name) · \(approver.role)")
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            Text(approver.note)
                                .tsFont(.caption2)
                                .foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                        StatusBadge(title: approver.status.title, tone: approver.status.tone)
                    }
                    .padding(.vertical, Spacing.md + Spacing.xxxs)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        }
    }
}

/// 첨부
struct AttachmentSection: View {
    let attachments: [ApprovalAttachment]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("첨부")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: Spacing.md) {
                ForEach(Array(attachments.enumerated()), id: \.offset) { _, file in
                    HStack(spacing: Spacing.md) {
                        IconTile(icon: .file, iconSize: .lg, tint: .tsPrimary, background: .tsPrimarySoft)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(file.name)
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            Text(file.sizeText)
                                .tsFont(.caption2)
                                .foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .tsCard(padding: Spacing.lg)
        }
    }
}

/// 코멘트 N
struct CommentSection: View {
    let comments: [ApprovalComment]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("코멘트 \(comments.count)")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            if comments.isEmpty {
                InfoBanner(message: "아직 남겨진 코멘트가 없어요.", icon: .infoCircle, style: .muted)
            } else {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(comments) { comment in
                        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
                            AvatarView(size: 32)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                HStack(spacing: Spacing.xs) {
                                    Text(comment.authorName)
                                        .tsFont(.footnoteBold)
                                        .foregroundStyle(Color.tsInk)
                                    Text(TSFormat.relative(comment.createdAt))
                                        .tsFont(.caption2)
                                        .foregroundStyle(Color.tsInk3)
                                }
                                Text(comment.body)
                                    .tsFont(.footnote)
                                    .foregroundStyle(Color.tsInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .tsCard(padding: Spacing.lg)
            }
        }
    }
}

/// 05-4 의견 남기기
struct CommentInputSection: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("의견 남기기")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            HStack(spacing: Spacing.sm) {
                TextField("검토 의견을 남겨주세요 (선택)", text: $text, axis: .vertical)
                    .tsFont(.footnote)
                    .lineLimit(1...4)
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .tsIconSize(.mdLarge)
                        .foregroundStyle(Color.tsOnPrimary)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.tsPrimary))
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                .accessibilityLabel("의견 보내기")
            }
            .padding(.leading, Spacing.lg)
            .padding(.trailing, Spacing.compact + Spacing.xxs)
            .padding(.vertical, Spacing.compact + Spacing.xxs)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.tsSurface))
        }
    }
}

extension ApproverStatus {
    var title: String {
        switch self {
        case .waiting: return "대기"
        case .reviewing: return "검토 중"
        case .approved: return "승인"
        case .rejected: return "반려"
        case .unknown: return "확인 중"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .waiting, .unknown: return .neutral
        case .reviewing: return .primary
        case .approved: return .positive
        case .rejected: return .negative
        }
    }
}
