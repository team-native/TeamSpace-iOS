import Foundation
import Observation

/// 04-6 돈의 구성 — 고른 달의 풀 배분을 그대로 씁니다. (별도 API 없음)
@Observable
@MainActor
final class FinanceCompositionViewModel {
    private(set) var state: ViewState<[FinancePool]> = .idle

    let month: Date
    private let fetchFinanceOverviewUseCase: FetchFinanceOverviewUseCase

    init(month: Date, fetchFinanceOverviewUseCase: FetchFinanceOverviewUseCase) {
        self.month = month
        self.fetchFinanceOverviewUseCase = fetchFinanceOverviewUseCase
    }

    /// 도넛 가운데 숫자 (비율 합)
    var totalRatio: Int {
        (state.value ?? []).reduce(0) { $0 + $1.ratio }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let pools = try await fetchFinanceOverviewUseCase.execute(month: month).pools
            state = pools.isEmpty ? .empty : .loaded(pools)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.composition")
            if state.value == nil { state = .failed(error) }
        }
    }
}
