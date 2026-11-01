import SwiftUI

/// 05-1 내가 올린 결재 — 상태 요약 + 최근 목록
struct MyApprovalsSection: View {
    let viewModel: ApprovalListViewModel
    let onOpen: (ApprovalItem) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.summaryStatuses, id: \.self) { status in
                VStack(spacing: Spacing.xs) {
                    Text("\(viewModel.count(of: status))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(status.summaryColor)
                    Text(status.badgeTitle)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.sm)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        HStack(spacing: Spacing.xs) {
            Text("내가 올린 결재")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            Spacer()
            Text("전체 \(viewModel.myTotalCount)건")
                .tsFont(.footnoteMedium)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.horizontal, Spacing.xxs)
        if viewModel.recentMine.isEmpty {
            InfoBanner(message: "아직 올린 결재가 없어요. ‘결재 올리기’로 첫 안건을 올려 보세요.", icon: .infoCircle, style: .muted)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentMine.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { TSDivider() }
                    Button { onOpen(item) } label: { MyApprovalRow(item: item) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xxs)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        }
    }
}

private struct MyApprovalRow: View {
    let item: ApprovalItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    StatusBadge(status: item.status, size: .small)
                    Text(item.metaText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text(item.title)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.sm)
            if let amount = item.amount {
                WonText(amount: amount)
            }
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.vertical, Spacing.lg)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// 05-2 받은 결재 — 검토 대기 카드 + 처리한 결재
struct ReceivedApprovalsSection: View {
    let viewModel: ApprovalListViewModel
    let onOpen: (ApprovalItem) -> Void

    var body: some View {
        if viewModel.waitingReceived.isEmpty {
            InfoBanner(message: "지금 검토할 결재가 없어요. 새 요청이 오면 알림으로 알려드릴게요.", icon: .infoCircle, style: .muted)
        } else {
            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.waitingReceived) { item in
                    Button { onOpen(item) } label: { WaitingApprovalCard(item: item) }
                        .buttonStyle(.plain)
                }
            }
        }
        let handled = viewModel.handledThisMonth()
        if !handled.isEmpty {
            HStack {
                Text("처리한 결재")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Spacer()
                Text("이번 달 \(handled.count)건")
                    .tsFont(.footnoteMedium)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.top, Spacing.xs)
            VStack(spacing: 0) {
                ForEach(Array(handled.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { TSDivider() }
                    Button { onOpen(item) } label: { MyApprovalRow(item: item) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.tsSurface))
        }
    }
}

/// 검토를 기다리는 결재 카드 (05-2)
private struct WaitingApprovalCard: View {
    let item: ApprovalItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            HStack(spacing: Spacing.sm + Spacing.xxxs) {
                AvatarView(size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(item.requesterName) · \(item.requesterDepartment)")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    Text("\(item.kind.title) · \(TSFormat.relative(item.updatedAt))")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Spacer(minLength: 0)
                StatusBadge(status: item.status)
            }
            Text(item.title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            HStack {
                if let amount = item.amount {
                    WonText(amount: amount)
                } else if let summary = item.summary {
                    Text(summary)
                        .tsFont(.footnoteMedium)
                        .foregroundStyle(Color.tsInk2)
                }
                Spacer()
                HStack(spacing: Spacing.compact) {
                    Text("검토하기")
                        .tsFont(.footnoteBold)
                    TSIcon.arrowRight.sized(.mdLarge)
                }
                .foregroundStyle(Color.tsPrimary)
            }
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.tsSurface))
        .accessibilityElement(children: .combine)
        .accessibilityHint("검토하기")
    }
}
