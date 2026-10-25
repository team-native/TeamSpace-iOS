import Foundation
import Observation

/// 04-5 월별 흐름
@Observable
@MainActor
final class MonthlyFlowViewModel {
    private(set) var state: ViewState<[MonthlyFlow]> = .idle
    /// 아래 카드에 보여줄 달 (막대를 누르면 바뀜, 기본은 마지막 달)
    var selectedMonth: Date?

    let endMonth: Date
    private let fetchMonthlyFlowsUseCase: FetchMonthlyFlowsUseCase

    init(endMonth: Date, fetchMonthlyFlowsUseCase: FetchMonthlyFlowsUseCase) {
        self.endMonth = endMonth
        self.fetchMonthlyFlowsUseCase = fetchMonthlyFlowsUseCase
    }

    private var flows: [MonthlyFlow] {
        state.value ?? []
    }

    var selectedFlow: MonthlyFlow? {
        flows.first { $0.month == selectedMonth } ?? flows.last
    }

    /// 막대 높이 기준 (가장 큰 금액)
    var maxAmount: Int {
        max(flows.map { max($0.income, $0.expense) }.max() ?? 1, 1)
    }

    var headline: String {
        switch FlowTrend.of(flows) {
        case .widening: return "수금과 지출의 간격이\n꾸준히 벌어지고 있어요"
        case .narrowing: return "수금과 지출의 간격이\n조금씩 좁아지고 있어요"
        case .steady: return "수금과 지출이\n비슷하게 유지되고 있어요"
        }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let result = try await fetchMonthlyFlowsUseCase.execute(endingAt: endMonth)
            state = result.isEmpty ? .empty : .loaded(result)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.flows")
            if state.value == nil { state = .failed(error) }
        }
    }

    func select(_ flow: MonthlyFlow) {
        selectedMonth = flow.month
    }
}
