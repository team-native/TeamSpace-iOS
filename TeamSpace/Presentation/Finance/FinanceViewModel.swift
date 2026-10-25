import Foundation
import Observation

/// 04-1 재무
@Observable
@MainActor
final class FinanceViewModel {
    private(set) var state: ViewState<FinanceOverview> = .idle
    private(set) var selectedMonth: Date
    var isPeriodPickerPresented = false

    let user: AuthUser
    private let fetchFinanceOverviewUseCase: FetchFinanceOverviewUseCase

    init(user: AuthUser, fetchFinanceOverviewUseCase: FetchFinanceOverviewUseCase, now: Date = Date()) {
        self.user = user
        self.fetchFinanceOverviewUseCase = fetchFinanceOverviewUseCase
        self.selectedMonth = Calendar.current.startOfMonth(for: now)
    }

    /// "2026년 10월"
    var monthTitle: String {
        TSFormat.yearMonth(selectedMonth)
    }

    /// "재정 정보는 권한별로 공개 범위가 달라요 · 내 권한: 구성원"
    var permissionNotice: String {
        "재정 정보는 권한별로 공개 범위가 달라요 · 내 권한: \(user.financeScopeTitle)"
    }

    var canViewDetail: Bool {
        user.can(.viewFinanceDetail)
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchFinanceOverviewUseCase.execute(month: selectedMonth))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.overview")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 04-4 기간 선택 완료
    func selectMonth(_ month: Date) async {
        isPeriodPickerPresented = false
        let start = Calendar.current.startOfMonth(for: month)
        guard start != selectedMonth else { return }
        selectedMonth = start
        state = .loading
        await load()
    }
}
