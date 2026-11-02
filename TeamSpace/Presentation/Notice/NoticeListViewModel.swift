import Foundation
import Observation

/// 10-5 공지 · 알아야 할 것들
@Observable
@MainActor
final class NoticeListViewModel {
    private(set) var state: ViewState<[NoticeSummary]> = .idle
    private(set) var paging = PagingState()
    var filter: NoticeFilter = .all
    /// 10-7 공지 작성 버튼
    let canPublish: Bool

    private let fetchNoticesUseCase: FetchNoticesUseCase
    private var generation = 0

    init(canPublish: Bool, fetchNoticesUseCase: FetchNoticesUseCase) {
        self.canPublish = canPublish
        self.fetchNoticesUseCase = fetchNoticesUseCase
    }

    var notices: [NoticeSummary] {
        (state.value ?? []).filter { filter.matches($0) }
    }

    func load() async {
        generation += 1
        if state.value == nil { state = .loading }
        do {
            let page = try await fetchNoticesUseCase.execute()
            state = .loaded(page.items)
            paging = PagingState(nextCursor: page.nextCursor)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "notice.list.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 다음 페이지를 뒤에 붙여요. (서버가 고정 → 최신순으로 줘요)
    func loadMore() async {
        guard let current = state.value, let cursor = paging.begin() else { return }
        let started = generation
        do {
            let page = try await fetchNoticesUseCase.execute(cursor: cursor)
            guard started == generation else { return }
            state = .loaded(current.appendingUnique(page.items))
            paging.finish(nextCursor: page.nextCursor)
        } catch {
            AppLog.record(error, context: "notice.list.loadMore")
            guard started == generation else { return }
            paging.fail()
        }
    }
}
