import Foundation

/// 불러온 은행 거래 한 줄 (GET /finance/bank-imports) — FA · Admin 이 확인하고 재정에 반영해요.
struct BankImport: Equatable, Identifiable, Sendable {
    enum Direction: String, Sendable {
        case inbound = "입금"
        case outbound = "출금"
    }

    enum Status: String, Sendable {
        case needsReview = "확인 필요"
        case autoMatched = "자동 매칭"
        case confirmed = "확인 완료"
        case excluded = "제외"
        case committed = "이미 반영됨"

        /// 아직 확인 · 제외를 고를 수 있어요.
        var isOpen: Bool { self == .needsReview || self == .autoMatched }
    }

    let id: String
    let date: Date
    let counterparty: String
    let amount: Int
    let direction: Direction
    var matchedProject: String?
    var status: Status
    var committedAt: Date?
    var committedBy: String?

    /// 입금은 연결된 수주 계약이 있어야 확인할 수 있어요. 출금은 바로 확인해요.
    var canConfirm: Bool {
        status.isOpen && (direction == .outbound || matchedProject?.isEmpty == false)
    }
}

/// POST /finance/bank-import-commits 결과
struct BankImportCommitResult: Equatable, Sendable {
    let committedCount: Int
    let receiptCount: Int
    let expenseCount: Int
}
