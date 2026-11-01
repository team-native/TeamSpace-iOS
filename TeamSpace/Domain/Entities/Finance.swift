import Foundation

/// 재정 풀 (운영풀 · 적립풀 · 배당풀)
enum FinancePoolKind: String, UnknownCaseDecodable, Hashable, Sendable {
    case operation = "OPERATION"
    case reserve = "RESERVE"
    case dividend = "DIVIDEND"
    case unknown = "UNKNOWN"

    static let unknownCase: FinancePoolKind = .unknown
}

struct FinancePool: Equatable, Hashable, Sendable {
    let kind: FinancePoolKind
    /// 배분 비율 (%)
    let ratio: Int
    let amount: Int
    /// 건수 (수주 카드에서만 사용)
    let count: Int?
}

/// 02-1 홈 · 재무 트래커 요약
struct FinanceSummary: Equatable, Sendable {
    let month: Date
    /// 지금 사용할 수 있는 금액
    let availableAmount: Int
    /// Native 보유금 (전체)
    let holdingAmount: Int
    /// 지난달 대비 증감률 (%)
    let changeRate: Double
    /// 최근 흐름 (스파크라인)
    let trend: [Int]
    let pools: [FinancePool]
    let monthIncome: Int
    let monthExpense: Int
}

/// 수주 상태
enum ContractStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case negotiating = "NEGOTIATING"
    case contracted = "CONTRACTED"
    case completed = "COMPLETED"
    case unknown = "UNKNOWN"

    static let unknownCase: ContractStatus = .unknown
}

struct Contract: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let amount: Int
    let contractedAt: Date
    let status: ContractStatus
}

struct Deposit: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    /// 예) 선금 · 잔금
    let kind: String
    let amount: Int
    let paidAt: Date
}

/// 02-1 홈 · 수주 · 입금 요약
struct ContractSummary: Equatable, Sendable {
    let totalAmount: Int
    let yearCount: Int
    let pools: [FinancePool]
    let recentContracts: [Contract]
    let recentDeposits: [Deposit]
}
