import Foundation

struct FetchMonthlyFlowsUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    /// 고른 달까지 최근 7개월 (Figma 04-5: 4월 ~ 10월), 오래된 달부터
    func execute(endingAt month: Date, count: Int = 7) async throws -> [MonthlyFlow] {
        try await financeRepository.fetchMonthlyFlows(endingAt: month, count: count)
            .sorted { $0.month < $1.month }
    }
}
