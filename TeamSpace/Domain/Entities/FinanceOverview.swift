import Foundation

/// 이번 달 들어온 돈 / 나간 돈
struct FinanceFlow: Equatable, Sendable {
    let amount: Int
    /// 예) 외주 프로젝트 3건
    let note: String
}

/// 04-1 재무 메인
struct FinanceOverview: Equatable, Sendable {
    let month: Date
    /// 이번 달 외주 수금액 (확정 + 예정)
    let collectedAmount: Int
    /// 서버가 아직 실제 데이터를 주지 않을 때 true ("데모 데이터" 칩)
    let isDemo: Bool
    let pools: [FinancePool]
    /// 지금 사용할 수 있는 금액 (운영풀 기준)
    let availableAmount: Int
    /// 지난달 대비 증감률 (%)
    let changeRate: Double
    let income: FinanceFlow
    let expense: FinanceFlow
    let updatedAt: Date
}
