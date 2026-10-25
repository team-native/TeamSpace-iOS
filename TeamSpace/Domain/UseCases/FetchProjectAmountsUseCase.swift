import Foundation

struct FetchProjectAmountsUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    /// 순서는 서버가 정한 순서(최근 수주 순)를 그대로 씁니다.
    func execute(year: Int) async throws -> ProjectAmountSummary {
        try await financeRepository.fetchProjectAmounts(year: year)
    }
}
