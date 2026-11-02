import Foundation

/// 재무 저장소 — TeamSpace-backend `/finance/*` (재정 권한이 없으면 403)
protocol FinanceRepository: Sendable {
    /// GET /finance/summary — 서버는 이번 달 기준, 다른 달은 flow 로 채워요
    func fetchOverview(month: Date) async throws -> FinanceOverview
    /// GET /finance/summary 의 flow — 오래된 달 → 최근 달 순
    func fetchMonthlyFlows(endingAt month: Date, count: Int) async throws -> [MonthlyFlow]
    /// GET /finance/receipts?from&to — 수금 내역을 프로젝트별로 묶어요
    func fetchProjectAmounts(year: Int) async throws -> ProjectAmountSummary
    /// GET /finance/receipts?from=YYYY-01-01&to=YYYY-12-31
    func fetchContracts(year: Int) async throws -> ContractLedger
    /// 수금 한 건 + GET /finance/contracts/{project}
    func fetchContract(id: Int) async throws -> ContractDetail
}
