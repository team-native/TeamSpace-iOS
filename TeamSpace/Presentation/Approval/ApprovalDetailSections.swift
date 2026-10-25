import SwiftUI

/// 05-3 내 결재 상세
struct MyApprovalDetailContent: View {
    let detail: ApprovalDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: detail.item.status)
                StatusBadge(title: detail.item.kind.longTitle, tone: .neutral)
            }
            Text(detail.item.title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            if let amount = detail.item.amount {
                WonText(amount: amount, size: 30)
            }
        }
        ApprovalProgressCard(status: detail.item.status)
        ApprovalInfoCard(fields: detail.fields, reason: detail.reason)
        ApproverLineSection(approvers: detail.approvers)
        if !detail.attachments.isEmpty {
            AttachmentSection(attachments: detail.attachments)
        }
        CommentSection(comments: detail.comments)
    }
}

/// 05-4 받은 결재 상세 (검토)
struct ReviewApprovalContent: View {
    let detail: ApprovalDetail
    let meta: String
    @Bindable var viewModel: ApprovalDetailViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(size: 40)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text("\(detail.item.requesterName) · \(detail.item.requesterDepartment)")
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Text(meta)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: 0)
            StatusBadge(status: detail.item.status)
        }
        .tsCard(padding: Spacing.lg)
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TagChip(title: detail.item.kind.longTitle, tone: .violet)
            Text(detail.item.title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
            if let amount = detail.item.amount {
                WonText(amount: amount, size: 24)
            }
        }
        ApprovalInfoCard(fields: detail.fields, reason: detail.reason)
        if detail.canDecide {
            CommentInputSection(text: $viewModel.commentDraft, isSending: viewModel.isProcessing) {
                Task { await viewModel.sendComment() }
            }
        }
        if !detail.comments.isEmpty {
            CommentSection(comments: detail.comments)
        }
    }
}

/// 작성 → 결재 대기 → 검토 중 → 승인/반려
struct ApprovalProgressCard: View {
    let status: ApprovalStatus

    private var titles: [String] {
        ["작성", "결재 대기", "검토 중", status == .rejected ? "반려" : "승인"]
    }

    private var reachedIndex: Int {
        switch status {
        case .draft, .unknown: return 0
        case .pending: return 1
        case .reviewing: return 2
        case .approved, .rejected: return 3
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                if index > 0 {
                    Rectangle()
                        .fill(index <= reachedIndex ? Color.tsPrimary : Color.tsLine)
                        .frame(height: 2)
                        .padding(.top, 15)
                }
                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle().fill(circleColor(index))
                        if index <= reachedIndex {
                            TSIcon.checkSmall.sized(.base)
                                .foregroundStyle(Color.tsOnPrimary)
                        }
                    }
                    .frame(width: 32, height: 32)
                    Text(title)
                        .font(.system(size: 10, weight: index == reachedIndex ? .bold : .medium))
                        .foregroundStyle(index == reachedIndex ? Color.tsPrimary : (index < reachedIndex ? Color.tsInk2 : Color.tsInk3))
                }
                .frame(width: 62)
            }
        }
        .frame(maxWidth: .infinity)
        .tsCard(padding: Spacing.xl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("진행 단계: \(titles[reachedIndex])")
    }

    private func circleColor(_ index: Int) -> Color {
        guard index <= reachedIndex else { return .tsSurface2 }
        return status == .rejected && index == reachedIndex ? .tsNegative : .tsPrimary
    }
}

/// 비용 유형 · 프로젝트 · 사용 예정일 + 요청 사유
struct ApprovalInfoCard: View {
    let fields: [ApprovalField]
    let reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                if index > 0 { TSDivider() }
                KeyValueRow(title: field.title, value: field.value)
            }
            TSDivider()
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("요청 사유")
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk3)
                Text(reason)
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.lg)
        }
        .padding(.horizontal, Spacing.xl)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
    }
}

/// 하단 두 버튼 (반려 · 승인하기 / 요청 취소 · 수정하기)
struct DualButtonBar: View {
    let leading: (title: String, action: () -> Void)
    let trailing: (title: String, action: () -> Void)
    let isLeadingDestructive: Bool
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: Spacing.sm + Spacing.xxxs) {
            Button(action: leading.action) {
                Text(leading.title)
                    .tsFont(.bodyBold)
                    .foregroundStyle(isLeadingDestructive ? Color.tsNegative : Color.tsInk2)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).fill(Color.tsSurface2))
            }
            .buttonStyle(.plain)
            Button(trailing.title, action: trailing.action)
                .buttonStyle(.tsPrimary)
        }
        .disabled(isDisabled)
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.md)
        .background(Color.tsSurface.ignoresSafeArea())
    }
}

extension ApprovalKind {
    /// "비용 승인" · "프로젝트 인력 지원"
    var longTitle: String {
        switch self {
        case .expense: return "비용 승인"
        case .staffing: return "프로젝트 인력 지원"
        case .other: return "기타 요청"
        case .unknown: return "결재"
        }
    }
}
