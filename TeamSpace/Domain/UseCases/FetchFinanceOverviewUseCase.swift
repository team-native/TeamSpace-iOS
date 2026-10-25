import Foundation

struct FetchFinanceOverviewUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    /// 풀은 운영 → 적립 → 배당 순으로 보여줍니다.
    func execute(month: Date) async throws -> FinanceOverview {
        let overview = try await financeRepository.fetchOverview(month: month)
        let order: [FinancePoolKind] = [.operation, .reserve, .dividend, .unknown]
        let pools = overview.pools.sorted {
            (order.firstIndex(of: $0.kind) ?? order.count) < (order.firstIndex(of: $1.kind) ?? order.count)
        }
        return FinanceOverview(
            month: overview.month,
            collectedAmount: overview.collectedAmount,
            isDemo: overview.isDemo,
            pools: pools,
            availableAmount: overview.availableAmount,
            changeRate: overview.changeRate,
            income: overview.income,
            expense: overview.expense,
            updatedAt: overview.updatedAt
        )
    }
}
