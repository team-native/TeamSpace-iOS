import SwiftUI

/// 02-1 재무 트래커 카드
struct HomeFinanceCard: View {
    let finance: FinanceSummary
    @Binding var mode: HomeFinanceMode
    let amount: Int
    let onDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            HStack {
                CardSectionHeader(title: "재무 트래커")
                Text(TSFormat.yearMonth(finance.month))
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .padding(.horizontal, Spacing.sm + Spacing.xxxs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.tsSurface2, in: Capsule())
            }
            TSSegmentedControl(
                items: HomeFinanceMode.allCases,
                selection: mode,
                title: { $0.title },
                onSelect: { mode = $0 }
            )
            amountSection
            SparklineView(values: finance.trend)
                .frame(height: 72)
            PoolRow(pools: finance.pools)
            flowRow
            Button(action: onDetail) {
                HStack(spacing: Spacing.xs) {
                    Text("재무 자세히 보기")
                        .tsFont(.footnoteBold)
                    TSIcon.arrowRight.sized(.mdLarge)
                }
                .foregroundStyle(Color.tsInk)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .tsCard(padding: Spacing.lg)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(mode.caption)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            AmountText(amount: amount)
            HStack(spacing: Spacing.xxs) {
                Text("지난달보다")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
                Text(TSFormat.signedPercent(finance.changeRate))
                    .tsFont(.captionBold)
                    .foregroundStyle(finance.changeRate >= 0 ? Color.tsPositive : Color.tsNegative)
            }
        }
    }

    private var flowRow: some View {
        HStack {
            FlowColumn(title: "이번 달 수금", value: TSFormat.signedWon(finance.monthIncome), color: .tsPositive)
            Spacer(minLength: Spacing.sm)
            Rectangle()
                .fill(Color.tsLine)
                .frame(width: 1, height: 36)
            Spacer(minLength: Spacing.sm)
            FlowColumn(title: "이번 달 지출", value: TSFormat.signedWon(-finance.monthExpense), color: .tsInk)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// 큰 금액 + "원" (28 Bold / 18 Bold)
struct AmountText: View {
    let amount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxxs) {
            Text(TSFormat.number(amount))
                .tsFont(.title1)
            Text("원")
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundStyle(Color.tsInk)
        .accessibilityElement(children: .combine)
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.2), value: amount)
    }
}

/// 운영풀 · 적립풀 · 배당풀 타일
struct PoolRow: View {
    let pools: [FinancePool]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(pools, id: \.self) { pool in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(pool.kind.title)
                            .tsFont(.caption2Bold)
                        Spacer(minLength: 0)
                        Text("\(pool.ratio)%")
                            .tsFont(.caption2)
                    }
                    Text(TSFormat.number(pool.amount))
                        .tsFont(.captionBold)
                    if let count = pool.count {
                        Text("\(count)건")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .foregroundStyle(pool.kind.tint)
                .padding(Spacing.sm + Spacing.xxxs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(pool.kind.background, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct FlowColumn: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.compact) {
            Text(title)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            Text(value)
                .tsFont(.footnoteBold)
                .foregroundStyle(color)
        }
    }
}
