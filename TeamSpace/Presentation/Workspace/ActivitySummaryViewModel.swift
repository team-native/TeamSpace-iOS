import Foundation
import Observation

/// 07-12 내 활동
@Observable
@MainActor
final class ActivitySummaryViewModel {
    private(set) var state: ViewState<ActivitySummary> = .idle

    private let fetchActivitySummaryUseCase: FetchActivitySummaryUseCase

    init(fetchActivitySummaryUseCase: FetchActivitySummaryUseCase) {
        self.fetchActivitySummaryUseCase = fetchActivitySummaryUseCase
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchActivitySummaryUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.activity.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
