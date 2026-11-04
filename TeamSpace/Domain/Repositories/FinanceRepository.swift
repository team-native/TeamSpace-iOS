import Foundation

/// 재무 저장소 — TeamSpace-backend `/finance/*` (요약은 모두, 수금 · 계약은 재정 권한이 없으면 403)
protocol FinanceRepository: Sendable {
    /// GET /finance/summary?month=YYYY-MM
    func fetchOverview(month: Date) async throws -> FinanceOverview
    /// GET /finance/summary 의 flow — 오래된 달 → 최근 달 순
    func fetchMonthlyFlows(endingAt month: Date, count: Int) async throws -> [MonthlyFlow]
    /// GET /finance/receipts?from&to — 수금 내역을 프로젝트별로 묶어요
    func fetchProjectAmounts(year: Int) async throws -> ProjectAmountSummary
    /// GET /finance/receipts?from=YYYY-01-01&to=YYYY-12-31
    func fetchContracts(year: Int) async throws -> ContractLedger
    /// GET /finance/summary 의 누적 수주 합계 — 재정 권한이 없는 구성원용 (수주 목록은 비어 있어요)
    func fetchPublicLedger(year: Int) async throws -> ContractLedger
    /// 수금 한 건 + GET /finance/contracts/{project}
    func fetchContract(id: Int) async throws -> ContractDetail
    /// POST /admin/finance/receipts — 새 수금 id
    func createReceipt(_ draft: ReceiptDraft) async throws -> Int
    /// PATCH /admin/finance/receipts/{id} — 바뀐 값만
    func updateReceipt(id: Int, changes: ReceiptChanges) async throws
}
