import Foundation
import Observation

/// 10-1 팀 게시판
/// 게시글은 서버가 분류 · 기간 · 정렬을 걸러서 페이지로 줘요. 조건을 바꾸면 첫 페이지부터 다시 받아요.
@Observable
@MainActor
final class BoardViewModel {
    /// 인기글 개수
    static let popularLimit = FetchBoardUseCase.popularLimit

    private(set) var state: ViewState<Board> = .idle
    private(set) var period: BoardPeriod = .week
    private(set) var filter: BoardFilter = .all
    private(set) var sort: BoardSort = .latest
    /// 지금 조건으로 받은 게시글 (페이지를 이어 붙여요)
    private(set) var posts: [PostSummary] = []
    private(set) var paging = PagingState()
    /// 게시글 목록을 처음 받는 중 (조건을 바꾼 직후)
    private(set) var isLoadingPosts = false

    private let fetchBoardUseCase: FetchBoardUseCase
    private let fetchPostsUseCase: FetchPostsUseCase
    private let now: () -> Date
    /// 조건을 바꾸면 올라가요 — 이전 조건의 응답은 버려요.
    private var generation = 0
    private var reloadTask: Task<Void, Never>?

    init(fetchBoardUseCase: FetchBoardUseCase, fetchPostsUseCase: FetchPostsUseCase, now: @escaping () -> Date = { Date() }) {
        self.fetchBoardUseCase = fetchBoardUseCase
        self.fetchPostsUseCase = fetchPostsUseCase
        self.now = now
    }

    var board: Board? { state.value }

    /// "고정 공지" — 전체 · 공지 칩에서만 보여요.
    var pinnedNotices: [NoticeSummary] {
        guard filter == .all || filter == .notice else { return [] }
        return board?.pinnedNotices ?? []
    }

    /// "이번 주 인기글" — 최근 7일 추천 많은 순
    var popularPosts: [PostSummary] {
        board?.popularPosts ?? []
    }

    /// "10.12 – 10.18"
    var popularRangeText: String {
        let today = Calendar.current.startOfDay(for: now())
        return "\(TSFormat.shortDate(today.addingTimeInterval(-6 * 86_400))) – \(TSFormat.shortDate(today))"
    }

    var inquiryCount: Int { board?.myRecord?.inquiries.count ?? 0 }

    var emptyMessage: String? {
        guard filter != .notice, posts.isEmpty, !isLoadingPosts, !paging.didFail else { return nil }
        return "\(period.title) 올라온 \(filter == .all ? "" : filter.title + " ")글이 없어요. 기간을 바꿔 보세요."
    }

    /// 지금 칩 · 기간 · 정렬을 서버 조건으로
    var query: PostListQuery {
        var query = PostListQuery(period: period.serverPeriod(now: now()), sort: sort == .popular ? .likes : .latest)
        if case .category(let category) = filter { query.category = category }
        return query
    }

    func selectPeriod(_ period: BoardPeriod) {
        guard self.period != period else { return }
        self.period = period
        scheduleReload()
    }

    func selectFilter(_ filter: BoardFilter) {
        guard self.filter != filter else { return }
        self.filter = filter
        scheduleReload()
    }

    func selectSort(_ sort: BoardSort) {
        guard self.sort != sort else { return }
        self.sort = sort
        scheduleReload()
    }

    /// "인기글 더 보기" — 이번 주 인기순으로 다시 받아요.
    func showPopular() {
        period = .week
        filter = .all
        sort = .popular
        scheduleReload()
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            async let board = fetchBoardUseCase.execute()
            async let firstPage: Void = reloadPosts()
            let loaded = try await board
            await firstPage
            state = .loaded(loaded)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "board.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 지금 조건으로 첫 페이지부터 다시 받아요. (공지 칩은 게시글을 보여주지 않아요)
    func reloadPosts() async {
        generation += 1
        let current = generation
        paging = PagingState()
        guard filter != .notice else {
            posts = []
            return
        }
        isLoadingPosts = true
        defer { if current == generation { isLoadingPosts = false } }
        do {
            let page = try await fetchPostsUseCase.execute(query, cursor: nil)
            guard current == generation else { return }
            posts = page.items
            paging.finish(nextCursor: page.nextCursor)
        } catch {
            guard current == generation else { return }
            AppLog.record(error, context: "board.posts")
            posts = []
            paging.fail()
        }
    }

    /// 목록 끝에 닿으면 다음 페이지
    func loadMore() async {
        guard let cursor = paging.begin() else { return }
        let current = generation
        do {
            let page = try await fetchPostsUseCase.execute(query, cursor: cursor)
            guard current == generation else { return }
            posts = posts.appendingUnique(page.items)
            paging.finish(nextCursor: page.nextCursor)
        } catch {
            guard current == generation else { return }
            AppLog.record(error, context: "board.loadMore")
            paging.fail()
        }
    }

    /// 칩을 연달아 눌러도 마지막 조건만 받아요.
    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in await self?.reloadPosts() }
    }

    /// 테스트용 — 조건을 바꾼 뒤 다시 받기가 끝날 때까지 기다려요.
    func waitForReload() async {
        await reloadTask?.value
    }
}
