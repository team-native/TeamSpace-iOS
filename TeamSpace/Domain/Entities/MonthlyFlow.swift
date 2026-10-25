import Foundation

/// 04-5 한 달의 들어온 돈 · 나간 돈
struct MonthlyFlow: Equatable, Identifiable, Sendable {
    let month: Date
    let income: Int
    let expense: Int

    var id: Date { month }

    /// 순이익
    var net: Int { income - expense }
}

/// 04-5 흐름 추세 — 카드 제목 문구에 사용
enum FlowTrend: Equatable, Sendable {
    /// 수금과 지출의 간격이 벌어지는 중
    case widening
    /// 간격이 줄어드는 중
    case narrowing
    case steady

    /// 앞 절반과 뒤 절반의 평균 순이익을 비교합니다.
    static func of(_ flows: [MonthlyFlow]) -> FlowTrend {
        guard flows.count >= 2 else { return .steady }
        let half = flows.count / 2
        let earlier = flows.prefix(half).map(\.net)
        let later = flows.suffix(flows.count - half).map(\.net)
        let earlierAverage = Double(earlier.reduce(0, +)) / Double(max(earlier.count, 1))
        let laterAverage = Double(later.reduce(0, +)) / Double(max(later.count, 1))
        let change = laterAverage - earlierAverage
        if abs(change) < max(abs(earlierAverage) * 0.05, 1) { return .steady }
        return change > 0 ? .widening : .narrowing
    }
}
