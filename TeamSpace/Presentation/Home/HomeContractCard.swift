import SwiftUI

/// 02-1 수주 · 입금 카드
struct HomeContractCard: View {
    let summary: ContractSummary
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            CardSectionHeader(title: "수주 · 입금", linkTitle: "전체 보기", onLink: onShowAll)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("누적 수주 금액")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    AmountText(amount: summary.totalAmount)
                    Text("올해 \(summary.yearCount)건")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            PoolRow(pools: summary.pools)
            VStack(alignment: .leading, spacing: Spacing.xxl + Spacing.hairline) {
                if !summary.recentContracts.isEmpty {
                    RecentList(title: "최근 수주") {
                        ForEach(summary.recentContracts) { contract in
                            MoneyRow(
                                title: contract.title,
                                subtitle: TSFormat.monthDay(contract.contractedAt),
                                amount: TSFormat.won(contract.amount),
                                amountColor: .tsInk
                            ) {
                                TagChip(title: contract.status.title, tone: contract.status.tone)
                            }
                        }
                    }
                }
                if !summary.recentDeposits.isEmpty {
                    RecentList(title: "최근 입금") {
                        ForEach(summary.recentDeposits) { deposit in
                            MoneyRow(
                                title: deposit.title,
                                subtitle: "\(deposit.kind) · \(TSFormat.monthDay(deposit.paidAt))",
                                amount: TSFormat.signedWon(deposit.amount),
                                amountColor: .tsPositive
                            ) {
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
        .tsCard(padding: Spacing.lg)
    }
}

/// "최근 수주" 같은 작은 제목 + 행 목록
struct RecentList<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            Text(title)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            VStack(spacing: Spacing.sm + Spacing.xxxs) {
                content()
            }
        }
    }
}

/// 제목 · 날짜 + 오른쪽 금액 (+ 칩) 한 줄, 아래 구분선
struct MoneyRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let amount: String
    let amountColor: Color
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        VStack(spacing: Spacing.sm + Spacing.xxxs) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Spacing.xs - 1) {
                    Text(title)
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsInk)
                        .lineLimit(1)
                    Text(subtitle)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                }
                Spacer(minLength: Spacing.md)
                VStack(alignment: .trailing, spacing: Spacing.xs - 1) {
                    Text(amount)
                        .tsFont(.calloutBold)
                        .foregroundStyle(amountColor)
                    accessory()
                }
            }
            .frame(minHeight: 52)
            TSDivider()
        }
        .accessibilityElement(children: .combine)
    }
}
