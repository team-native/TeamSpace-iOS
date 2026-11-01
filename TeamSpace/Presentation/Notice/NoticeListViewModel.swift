import Foundation
import Observation

/// 10-5 공지 · 알아야 할 것들
@Observable
@MainActor
final class NoticeListViewModel {
    private(set) var state: ViewState<[NoticeSummary]> = .idle
    var filter: NoticeFilter = .all
    /// 10-7 공지 작성 버튼
    let canPublish: Bool

    private let fetchNoticesUseCase: FetchNoticesUseCase

    init(canPublish: Bool, fetchNoticesUseCase: FetchNoticesUseCase) {
        self.canPublish = canPublish
        self.fetchNoticesUseCase = fetchNoticesUseCase
    }

    var notices: [NoticeSummary] {
        (state.value ?? []).filter { filter.matches($0) }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchNoticesUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "notice.list.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
