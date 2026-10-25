import Foundation
import Observation

/// 04-3 수금 내역 전체
@Observable
@MainActor
final class ContractLedgerViewModel {
    private(set) var state: ViewState<ContractLedger> = .idle
    var filter: CollectionFilter = .all
    var sort: CollectionSort = .latest

    let year: Int
    private let fetchContractLedgerUseCase: FetchContractLedgerUseCase

    init(year: Int, fetchContractLedgerUseCase: FetchContractLedgerUseCase) {
        self.year = year
        self.fetchContractLedgerUseCase = fetchContractLedgerUseCase
    }

    /// "2026년 누적 수주"
    var totalTitle: String {
        "\(year)년 누적 수주"
    }

    private var filteredContracts: [FinanceContract] {
        (state.value?.contracts ?? []).filter { filter.matches($0) }
    }

    /// 최신순이면 달별로 묶고, 금액순이면 한 묶음으로 보여줘요.
    var groups: [ContractMonthGroup] {
        switch sort {
        case .latest:
            return FetchContractLedgerUseCase.groupByMonth(filteredContracts)
        case .amount:
            let sorted = filteredContracts.sorted { $0.amount > $1.amount }
            guard let first = sorted.first else { return [] }
            return [ContractMonthGroup(id: "amount", month: first.collectedAt, contracts: sorted)]
        }
    }

    func groupTitle(_ group: ContractMonthGroup) -> String {
        sort == .amount ? "금액 큰 순" : TSFormat.month(group.month)
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchContractLedgerUseCase.execute(year: year))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.contracts")
            if state.value == nil { state = .failed(error) }
        }
    }
}
