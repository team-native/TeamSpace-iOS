import Foundation

/// 재무 저장소 — 명세서에 재무 API 가 없어 경로는 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol FinanceRepository: Sendable {
    /// GET /finance/overview?month=2026-10
    func fetchOverview(month: Date) async throws -> FinanceOverview
    /// GET /finance/flows?to=2026-10&months=7 — 오래된 달 → 최근 달 순
    func fetchMonthlyFlows(endingAt month: Date, count: Int) async throws -> [MonthlyFlow]
    /// GET /finance/projects?year=2026 — 재정 권한이 없으면 금액은 null
    func fetchProjectAmounts(year: Int) async throws -> ProjectAmountSummary
    /// GET /finance/contracts?year=2026
    func fetchContracts(year: Int) async throws -> ContractLedger
    /// GET /finance/contracts/{contractId}
    func fetchContract(id: Int) async throws -> ContractDetail
}
