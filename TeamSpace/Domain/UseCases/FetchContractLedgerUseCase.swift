import Foundation

struct FetchContractLedgerUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    func execute(year: Int) async throws -> ContractLedger {
        try await financeRepository.fetchContracts(year: year)
    }

    /// 최근 달이 위로, 한 달 안에서는 최근 날짜가 위로 오도록 묶습니다.
    static func groupByMonth(_ contracts: [FinanceContract], calendar: Calendar = .current) -> [ContractMonthGroup] {
        let grouped = Dictionary(grouping: contracts) { calendar.startOfMonth(for: $0.collectedAt) }
        return grouped.keys.sorted(by: >).map { month in
            ContractMonthGroup(
                id: "\(calendar.component(.year, from: month))-\(calendar.component(.month, from: month))",
                month: month,
                contracts: (grouped[month] ?? []).sorted { $0.collectedAt > $1.collectedAt }
            )
        }
    }
}
