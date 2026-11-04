import Foundation

/// GET /finance/bank-imports 한 항목 (TeamSpace-backend `finance.get_bank_imports`)
struct ServerBankImportDTO: Decodable {
    let rowId: String
    let date: String
    let counterparty: String?
    let amount: Int
    let direction: String
    let matchedProject: String?
    let status: String
    let committedAt: String?
    let committedBy: String?

    func toEntity() -> BankImport? {
        guard let direction = BankImport.Direction(rawValue: direction), let status = BankImport.Status(rawValue: status) else {
            return nil
        }
        return BankImport(
            id: rowId,
            date: ServerDate.parse(date) ?? .distantPast,
            counterparty: counterparty ?? "",
            amount: amount,
            direction: direction,
            matchedProject: matchedProject,
            status: status,
            committedAt: committedAt.flatMap(ServerDate.parse),
            committedBy: committedBy
        )
    }
}

/// PATCH /finance/bank-imports/{rowId} 요청 · 응답
struct ServerBankImportReviewRequestDTO: Codable, Equatable {
    /// 비우면 보내지 않아요 (지금 연결을 그대로 써요).
    var matchedProject: String? = nil
    let confirm: Bool
    let exclude: Bool
}

struct ServerBankImportReviewDTO: Decodable {
    let rowId: String
    let status: String
    let matchedProject: String?
}

/// POST /finance/bank-import-commits 요청 · 응답
struct ServerBankImportCommitRequestDTO: Codable, Equatable {
    let rowIds: [String]
}

struct ServerBankImportCommitDTO: Decodable {
    let committedCount: Int
    let receiptCount: Int
    let expenseCount: Int
}

/// GET /finance/bank-accounts
struct ServerBankAccountDTO: Decodable {
    struct MonthCount: Decodable {
        let inboundCount: Int?
        let outboundCount: Int?
    }

    let configured: Bool?
    let connectionStatus: String?
    let alias: String?
    let accountNumber: String?
    let lastSyncedAt: String?
    let thisMonth: MonthCount?
    let consecutiveFailures: Int?

    func toEntity() -> BankAccountStatus {
        BankAccountStatus(
            connectionStatus: connectionStatus ?? "not_configured",
            configured: configured ?? false,
            alias: alias,
            accountNumber: accountNumber,
            lastSyncedAt: lastSyncedAt.flatMap(ServerDate.parse),
            inboundCount: thisMonth?.inboundCount ?? 0,
            outboundCount: thisMonth?.outboundCount ?? 0,
            consecutiveFailures: consecutiveFailures ?? 0
        )
    }
}

/// POST /finance/bank-syncs 응답
struct ServerBankSyncDTO: Decodable {
    let fetchedCount: Int
    let importedCount: Int
    let lastSyncedAt: String?
}
