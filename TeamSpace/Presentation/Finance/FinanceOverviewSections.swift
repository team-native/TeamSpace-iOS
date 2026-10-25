import SwiftUI

/// 04-1 이번 달 외주 수금액 + 풀 배분
struct FinanceTrackerCard: View {
    let overview: FinanceOverview

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.xs) {
                    Circle().fill(Color.tsPrimary).frame(width: 6, height: 6)
                    Text("이번 달 외주 수금액")
                        .tsFont(.caption2Bold)
                        .foregroundStyle(Color.tsInk2)
                }
                Spacer()
                if overview.isDemo {
                    Text("데모 데이터")
                        .tsFont(.micro)
                        .foregroundStyle(Color.tsInk3)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.compact)
                        .background(Color.tsSurface2, in: Capsule())
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.compact) {
                Text(TSFormat.number(overview.collectedAmount))
                    .tsFont(.display)
                Text("원")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color.tsInk)
            .contentTransition(.numericText())
            Text("확정 · 예정 수금을 세 개의 풀로 자동 배분해요")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
            PoolBar(pools: overview.pools)
            VStack(spacing: 0) {
                ForEach(overview.pools, id: \.self) { pool in
                    PoolLegendRow(pool: pool)
                }
            }
        }
        .padding(Spacing.xl)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
    }
}

/// 비율대로 나눈 가로 막대
private struct PoolBar: View {
    let pools: [FinancePool]

    var body: some View {
        GeometryReader { proxy in
            let total = max(pools.reduce(0) { $0 + $1.ratio }, 1)
            let spacing = Spacing.xxxs * CGFloat(max(pools.count - 1, 0))
            HStack(spacing: Spacing.xxxs) {
                ForEach(pools, id: \.self) { pool in
                    Capsule()
                        .fill(LinearGradient(colors: [pool.kind.tint, pool.kind.tint.opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: (proxy.size.width - spacing) * CGFloat(pool.ratio) / CGFloat(total))
                }
            }
        }
        .frame(height: 7)
        .accessibilityHidden(true)
    }
}

private struct PoolLegendRow: View {
    let pool: FinancePool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle().fill(pool.kind.tint).frame(width: 8, height: 8)
            Text(pool.kind.title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            Spacer()
            Text(TSFormat.won(pool.amount))
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk2)
            Text("\(pool.ratio)%")
                .tsFont(.caption2Bold)
                .foregroundStyle(Color.tsInk3)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

/// 04-1 돈의 흐름을 요약했어요
struct FinanceSummarySection: View {
    let overview: FinanceOverview

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text("돈의 흐름을 요약했어요")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text("마지막 업데이트 · \(TSFormat.relative(overview.updatedAt))")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            availableCard
            HStack(spacing: Spacing.sm + Spacing.xxxs) {
                FlowCard(title: "이번 달 들어온 돈", flow: overview.income, sign: 1, color: .tsPositive)
                FlowCard(title: "이번 달 나간 돈", flow: overview.expense, sign: -1, color: .tsNegative)
            }
        }
    }

    private var availableCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("지금 사용할 수 있는 금액")
                    .tsFont(.caption)
                Spacer()
                Text("운영풀 기준")
                    .tsFont(.caption2)
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.compact) {
                Text(TSFormat.number(overview.availableAmount))
                    .tsFont(.amount)
                Text("원")
                    .font(.system(size: 16, weight: .bold))
            }
            Text(changeText)
                .tsFont(.captionMedium)
        }
        .foregroundStyle(Color.tsOnPrimary)
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TSGradient.primaryCard, in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// "지난달보다 12.8% 늘었어요 ↑"
    private var changeText: String {
        let rate = String(format: "%.1f", abs(overview.changeRate))
        return overview.changeRate >= 0 ? "지난달보다 \(rate)% 늘었어요 ↑" : "지난달보다 \(rate)% 줄었어요 ↓"
    }
}

private struct FlowCard: View {
    let title: String
    let flow: FinanceFlow
    let sign: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            Text(TSFormat.signedWon(flow.amount * sign))
                .tsFont(.calloutBold)
                .foregroundStyle(color)
            Text(flow.note)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// 04-1 월별 흐름 · 돈의 구성 · 이번 달 수금 현황
struct FinanceMenuList: View {
    /// 04-4 에서 고른 달
    let month: Date
    let onSelect: (AppRoute) -> Void

    private var items: [(title: String, route: AppRoute)] {
        [
            ("월별 흐름", .financeMonthlyFlow(month: month)),
            ("돈의 구성", .financeComposition(month: month)),
            ("이번 달 수금 현황", .financeContractLedger),
            ("프로젝트별 금액", .financeProjectAmounts)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 { TSDivider() }
                Button {
                    onSelect(item.route)
                } label: {
                    HStack {
                        Text(item.title)
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                        Spacer()
                        TSIcon.chevronRight.sized(.base)
                            .foregroundStyle(Color.tsInk3)
                    }
                    .padding(.vertical, Spacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.xxs)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
    }
}
