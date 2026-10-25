import SwiftUI

/// 04-6 돈의 구성
struct FinanceCompositionView: View {
    @State private var viewModel: FinanceCompositionViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: FinanceCompositionViewModel) {
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
            TSNavigationBar(title: "돈의 구성", onBack: { dismiss() })
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
            InfoBanner(message: "아직 배분된 돈이 없어요.", icon: .infoCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "돈의 구성을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let pools):
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("풀 배분")
                        .tsFont(.captionMedium)
                        .foregroundStyle(Color.tsInk3)
                    Text("들어온 돈은\n이렇게 나뉘고 있어요")
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                }
                PoolDonut(pools: pools, totalRatio: viewModel.totalRatio)
                    .frame(maxWidth: .infinity)
                PoolDescriptionList(pools: pools)
            }
            .tsCard(padding: Spacing.xl)
        }
    }
}

/// 비율 도넛 — 조각 사이 작은 틈
private struct PoolDonut: View {
    let pools: [FinancePool]
    let totalRatio: Int

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(
                        AngularGradient(colors: [segment.color, segment.color.opacity(0.5)], center: .center),
                        style: StrokeStyle(lineWidth: 22, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text("\(totalRatio)%")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                Text("자동 배분")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
        }
        .frame(width: 138, height: 138)
        .padding(11)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pools.map { "\($0.kind.title) \($0.ratio)%" }.joined(separator: ", "))
    }

    private var segments: [(start: CGFloat, end: CGFloat, color: Color)] {
        let total = CGFloat(max(pools.reduce(0) { $0 + $1.ratio }, 1))
        let gap: CGFloat = 0.01
        var start: CGFloat = 0
        return pools.map { pool in
            let length = CGFloat(pool.ratio) / total
            defer { start += length }
            return (start, max(start + length - gap, start), pool.kind.tint)
        }
    }
}

/// 풀별 설명 + 비율
private struct PoolDescriptionList: View {
    let pools: [FinancePool]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(pools.enumerated()), id: \.offset) { index, pool in
                if index > 0 { TSDivider() }
                HStack(spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(pool.kind.tint)
                        .frame(width: 12, height: 12)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: Radius.sm).fill(pool.kind.background))
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(pool.kind.title)
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                        Text(pool.kind.purpose)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    Spacer(minLength: 0)
                    Text("\(pool.ratio)%")
                        .tsFont(.subheadline)
                        .foregroundStyle(pool.kind.tint)
                }
                .padding(.vertical, Spacing.md + Spacing.xxxs)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

extension FinancePoolKind {
    /// 04-6 풀 설명
    var purpose: String {
        switch self {
        case .operation: return "지금 사용할 수 있는 운영 자금"
        case .reserve: return "다음 프로젝트를 위해 모아두는 자금"
        case .dividend: return "기여도에 따라 배분되는 비율"
        case .unknown: return "분류되지 않은 자금"
        }
    }
}

#Preview {
    NavigationStack {
        FinanceCompositionView(viewModel: DIContainer.preview().makeFinanceCompositionViewModel(month: Date()))
    }
}
