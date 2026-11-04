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

/// 은행 계좌 연동 상태 (GET /finance/bank-accounts)
struct BankAccountStatus: Equatable, Sendable {
    /// 서버 `connectionStatus` — connected · provider_pending · not_configured
    let connectionStatus: String
    let configured: Bool
    let alias: String?
    /// 끝 4자리만 보이는 번호 (예: ******1234)
    let accountNumber: String?
    let lastSyncedAt: Date?
    let inboundCount: Int
    let outboundCount: Int
    let consecutiveFailures: Int

    /// "NativeOps 운영 계좌 · ******1234"
    var title: String {
        let parts = [alias, accountNumber].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? "연결된 계좌 없음" : parts.joined(separator: " · ")
    }

    var connectionText: String {
        switch connectionStatus {
        case "connected": return "연결됨"
        case "provider_pending": return "은행 연동 준비 중"
        default: return "계좌 설정 전"
        }
    }

    /// 계좌 설정이 끝나야 불러오기를 시도해요.
    var canSync: Bool { configured }
}

/// POST /finance/bank-syncs 결과
struct BankSyncResult: Equatable, Sendable {
    let fetchedCount: Int
    let importedCount: Int
    let lastSyncedAt: Date?
}
