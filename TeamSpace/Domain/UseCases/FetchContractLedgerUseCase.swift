import Foundation

struct FetchContractLedgerUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    func execute(year: Int) async throws -> ContractLedger {
        try await financeRepository.fetchContracts(year: year)
    }

    /// 수금 내역을 볼 권한이 없으면 공개 요약(누적 수주 합계)으로 대신해요.
    func executeOrPublic(year: Int) async throws -> ContractLedger {
        do {
            return try await financeRepository.fetchContracts(year: year)
        } catch AppError.forbidden {
            return try await financeRepository.fetchPublicLedger(year: year)
        }
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
