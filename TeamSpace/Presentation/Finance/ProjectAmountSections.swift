import SwiftUI

/// 04-9 누적 수주 금액 카드
struct AmountSummaryCard: View {
    let summary: ProjectAmountSummary
    let paidPercent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("누적 수주 금액")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(TSFormat.number(summary.totalContractAmount ?? 0))
                        .font(.system(size: 32, weight: .bold))
                    Text("원")
                        .font(.system(size: 15, weight: .bold))
                    Text("올해 \(summary.yearCount)건")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                }
                .foregroundStyle(Color.tsInk)
            }
            TSProgressBar(percent: paidPercent, tint: .tsPositive)
            HStack {
                LabeledAmount(title: "누적 입금", value: TSFormat.won(summary.totalPaidAmount ?? 0), color: .tsPositive)
                Spacer()
                LabeledAmount(title: "미수금", value: TSFormat.won(summary.totalUnpaidAmount ?? 0), color: .tsInk)
            }
        }
        .tsCard(padding: Spacing.lg + Spacing.xxxs)
    }
}

/// 04-9 프로젝트 한 건 카드
struct ProjectAmountCard: View {
    let project: ProjectAmount

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(project.name)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
                Spacer(minLength: Spacing.sm)
                TagChip(title: project.status.title, tone: project.status.tone)
            }
            HStack {
                LabeledAmount(title: "수주 금액", value: TSFormat.won(project.contractAmount ?? 0), color: .tsInk)
                Spacer()
                LabeledAmount(title: "입금 합계", value: TSFormat.won(project.paidAmount ?? 0), color: .tsPositive)
            }
            TSProgressBar(percent: project.paidPercent ?? 0, tint: .tsPositive)
            HStack {
                Text("입금률 \(project.paidPercent ?? 0)%")
                Spacer()
                Text(unpaidText)
            }
            .tsFont(.caption)
            .foregroundStyle(Color.tsInk2)
        }
        .tsCard(padding: Spacing.lg + Spacing.xxxs)
        .accessibilityElement(children: .combine)
    }

    private var unpaidText: String {
        guard let unpaid = project.unpaidAmount, unpaid > 0 else { return "미수금 없음" }
        return "미수금 \(TSFormat.won(unpaid))"
    }
}

private struct LabeledAmount: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            Text(value)
                .tsFont(.bodyBold)
                .foregroundStyle(color)
        }
    }
}

/// "외 5개 프로젝트 보기"
struct ShowMoreRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Text(title)
                    .tsFont(.calloutBold)
                TSIcon.chevronDown.sized(.base, weight: .semibold)
            }
            .foregroundStyle(Color.tsInk)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        }
        .buttonStyle(.plain)
    }
}

/// 04-8 재무 · 권한 없음 — 건수만 보여주고 금액은 가림
struct HiddenAmountContent: View {
    let summary: ProjectAmountSummary
    let onRequestAccess: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            IconTile(icon: .lock, iconSize: .xxl, tileSize: 56, tint: .tsInk2, background: .tsSurface2, isCircle: true)
            Text("금액은 재정 권한이 있는\n팀원에게만 보여요")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(Color.tsInk)
                .multilineTextAlignment(.center)
            Text("프로젝트 진행 현황과 건수는\n권한 없이도 확인할 수 있어요.")
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .tsCard(padding: Spacing.xxl)
        HStack(spacing: Spacing.sm) {
            CountTile(title: "진행 중인 프로젝트", count: summary.inProgressCount)
            CountTile(title: "이번 달 신규 수주", count: summary.monthNewContracts)
            CountTile(title: "이번 달 입금", count: summary.monthDeposits)
        }
        VStack(alignment: .leading, spacing: 0) {
            Text("프로젝트별 금액")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
                .padding(.bottom, Spacing.sm)
            ForEach(Array(summary.projects.prefix(3).enumerated()), id: \.element.id) { index, project in
                if index > 0 { TSDivider() }
                HiddenProjectRow(project: project)
            }
        }
        .tsCard(padding: Spacing.lg + Spacing.xxxs)
        Button("재무 열람 권한 문의하기", action: onRequestAccess)
            .tsFont(.calloutBold)
            .foregroundStyle(Color.tsPrimary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.tsSurface))
            .buttonStyle(.plain)
    }
}

private struct CountTile: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(count)건")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.tsInk)
        }
        .frame(maxWidth: .infinity, minHeight: 63, alignment: .topLeading)
        .tsCard(padding: Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}

private struct HiddenProjectRow: View {
    let project: ProjectAmount

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(project.name)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Spacer(minLength: Spacing.sm)
                TagChip(title: project.status.title, tone: project.status.tone)
            }
            Text("•••,•••원")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk3)
                .accessibilityLabel("금액 비공개")
        }
        .padding(.vertical, Spacing.md + Spacing.xxxs)
    }
}
