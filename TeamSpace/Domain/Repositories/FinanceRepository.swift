import Foundation

/// 재무 저장소 — 명세서에 재무 API 가 없어 경로는 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol FinanceRepository: Sendable {
    /// GET /finance/overview?month=2026-10
    func fetchOverview(month: Date) async throws -> FinanceOverview
    /// GET /finance/contracts?year=2026
    func fetchContracts(year: Int) async throws -> ContractLedger
    /// GET /finance/contracts/{contractId}
    func fetchContract(id: Int) async throws -> ContractDetail
}
