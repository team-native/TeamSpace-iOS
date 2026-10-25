import Foundation
import Observation

/// 02-1 홈
@Observable
@MainActor
final class HomeViewModel {
    private(set) var state: ViewState<DashboardHome> = .idle
    var financeMode: HomeFinanceMode = .available

    private let fetchDashboardHomeUseCase: FetchDashboardHomeUseCase

    init(fetchDashboardHomeUseCase: FetchDashboardHomeUseCase) {
        self.fetchDashboardHomeUseCase = fetchDashboardHomeUseCase
    }

    var unreadNotificationCount: Int {
        state.value?.unreadNotificationCount ?? 0
    }

    /// "옥물결 님, 오늘 확인할 일이 3건 있어요."
    func greeting(for name: String) -> String {
        guard let count = state.value?.todayTaskCount, count > 0 else {
            return "\(name) 님, 오늘 확인할 일은 모두 끝냈어요."
        }
        return "\(name) 님, 오늘 확인할 일이 \(count)건 있어요."
    }

    /// 선택한 기준의 금액
    func financeAmount(_ finance: FinanceSummary) -> Int {
        switch financeMode {
        case .available: return finance.availableAmount
        case .holding: return finance.holdingAmount
        }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchDashboardHomeUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "dashboardHome.load")
            // 당겨서 새로고침이 실패하면 보던 내용은 그대로 둡니다.
            if state.value == nil { state = .failed(error) }
        }
    }
}
