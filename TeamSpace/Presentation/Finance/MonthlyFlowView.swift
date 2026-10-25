import SwiftUI

/// 04-5 월별 흐름
struct MonthlyFlowView: View {
    @State private var viewModel: MonthlyFlowViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MonthlyFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "월별 흐름", onBack: { dismiss() })
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 280)
        case .empty:
            InfoBanner(message: "아직 기록된 흐름이 없어요.", icon: .infoCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "월별 흐름을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let flows):
            FlowChartCard(
                headline: viewModel.headline,
                flows: flows,
                maxAmount: viewModel.maxAmount,
                selectedMonth: viewModel.selectedFlow?.month,
                onSelect: { viewModel.select($0) }
            )
            if let flow = viewModel.selectedFlow {
                FlowInsightCard(flow: flow)
            }
        }
    }
}

/// 월별 현금 흐름 막대 그래프
private struct FlowChartCard: View {
    let headline: String
    let flows: [MonthlyFlow]
    let maxAmount: Int
    let selectedMonth: Date?
    let onSelect: (MonthlyFlow) -> Void

    private let chartHeight: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("월별 현금 흐름")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
                Text(headline)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
            }
            HStack(spacing: Spacing.lg) {
                LegendItem(color: .tsPrimary, title: "들어온 돈")
                LegendItem(color: .tsLine, title: "나간 돈")
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(flows) { flow in
                    Button { onSelect(flow) } label: { bar(for: flow) }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(TSFormat.month(flow.month)), 들어온 돈 \(TSFormat.won(flow.income)), 나간 돈 \(TSFormat.won(flow.expense))")
                }
            }
            .frame(height: chartHeight + 24, alignment: .bottom)
        }
        .tsCard(padding: Spacing.xl)
    }

    private func bar(for flow: MonthlyFlow) -> some View {
        let isSelected = flow.month == selectedMonth
        return VStack(spacing: Spacing.sm) {
            HStack(alignment: .bottom, spacing: Spacing.xxs) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color.tsPrimary.opacity(0.45), Color.tsPrimary], startPoint: .top, endPoint: .bottom))
                    .frame(width: 8, height: height(flow.income))
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.tsLine)
                    .frame(width: 8, height: height(flow.expense))
            }
            Text(TSFormat.month(flow.month))
                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Color.tsInk : Color.tsInk3)
        }
        .contentShape(Rectangle())
    }

    private func height(_ amount: Int) -> CGFloat {
        max(chartHeight * CGFloat(amount) / CGFloat(maxAmount), 4)
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 8)
            Text(title)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

/// 고른 달 현황 — 들어온 돈 · 나간 돈 · 순이익
private struct FlowInsightCard: View {
    let flow: MonthlyFlow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            Text("\(TSFormat.month(flow.month)) 현황")
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsPrimary)
            VStack(spacing: Spacing.sm + Spacing.xxxs) {
                row(title: "들어온 돈", value: TSFormat.won(flow.income), color: .tsPrimary)
                row(title: "나간 돈", value: TSFormat.won(flow.expense), color: .tsInk)
                row(title: "순이익", value: TSFormat.signedWon(flow.net), color: flow.net >= 0 ? .tsPositive : .tsNegative)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsPrimarySoft))
    }

    private func row(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
            Spacer()
            Text(value)
                .tsFont(.calloutBold)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MonthlyFlowView(viewModel: DIContainer.preview().makeMonthlyFlowViewModel(endMonth: Date()))
    }
}
