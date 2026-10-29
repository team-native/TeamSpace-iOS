import XCTest
@testable import TeamSpace

@MainActor
final class BoardTests: XCTestCase {
    private func makeContainer(defaultsName: String = #function) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let defaults = UserDefaults(suiteName: "test.board.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsRecentSearchRepository.boardKey)
        return DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            boardRecentSearchRepository: UserDefaultsRecentSearchRepository(
                defaults: defaults,
                key: UserDefaultsRecentSearchRepository.boardKey,
                seed: MockBoardStore.recentKeywords
            )
        )
    }

    // MARK: 10-1 팀 게시판

    func testBoardShowsThisWeekLatestFirst() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.period, .week)
        XCTAssertEqual(viewModel.posts.map(\.id), [41, 40, 31, 39, 36, 35, 28, 37, 34], "최근 7일 · 최신순")
        XCTAssertEqual(viewModel.pinnedNotices.map(\.title), ["10월 프로젝트 정산 기준 안내", "외주 프로젝트 착수 전 체크리스트"])
        XCTAssertEqual(viewModel.posts.first?.authorText, "익명")
        XCTAssertEqual(viewModel.posts.dropFirst().first?.authorText, "김민준 · Leader")
        XCTAssertEqual(viewModel.inquiryCount, 2)
        XCTAssertEqual(viewModel.board?.myRecord.proposalCount, 3)
    }

    func testBoardFiltersAndSort() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        viewModel.filter = .category(.question)
        XCTAssertEqual(viewModel.posts.map(\.id), [41, 39, 28, 34])
        XCTAssertTrue(viewModel.pinnedNotices.isEmpty, "분류를 고르면 고정 공지는 숨겨요")

        viewModel.filter = .notice
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.pinnedNotices.count, 2)
        XCTAssertNil(viewModel.emptyMessage)

        viewModel.filter = .all
        viewModel.period = .today
        XCTAssertEqual(viewModel.posts.map(\.id), [41, 40])

        viewModel.period = .all
        XCTAssertEqual(viewModel.posts.count, 14)
        viewModel.sort = .popular
        XCTAssertEqual(viewModel.posts.first?.id, 36, "추천 33")
    }

    func testPopularPostsAndShowMore() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.popularPosts.map(\.id), [36, 35, 37], "이번 주 추천 많은 순 3개")
        XCTAssertEqual(viewModel.popularPosts.first?.reactionText, "익명 · 추천 33 · 댓글 9")

        viewModel.filter = .category(.info)
        viewModel.period = .today
        viewModel.showPopular()
        XCTAssertEqual(viewModel.filter, .all)
        XCTAssertEqual(viewModel.period, .week)
        XCTAssertEqual(viewModel.posts.prefix(3).map(\.id), [36, 35, 37])
    }

    func testCustomPeriodIncludesWholeDays() {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now).addingTimeInterval(-3 * 86_400)
        let period = BoardPeriod.custom(start: start.addingTimeInterval(3_600), end: start)

        XCTAssertTrue(period.contains(start, now: now), "시작일 0시")
        XCTAssertTrue(period.contains(start.addingTimeInterval(86_399), now: now), "종료일 23:59")
        XCTAssertFalse(period.contains(start.addingTimeInterval(86_400), now: now))
        XCTAssertEqual(BoardPeriod.week.title, "이번 주")
    }

    // MARK: 10-12 게시글 검색

    func testSearchFindsNoticeAndPosts() async {
        let viewModel = makeContainer().makeBoardSearchViewModel()
        XCTAssertEqual(viewModel.recentKeywords, MockBoardStore.recentKeywords)

        viewModel.query = "정산"
        await viewModel.search()

        XCTAssertEqual(viewModel.resultTitle, "정산 검색 결과 4건")
        XCTAssertEqual(viewModel.result.notices.map(\.title), ["10월 프로젝트 정산 기준 안내"])
        XCTAssertEqual(viewModel.result.posts.map(\.title), [
            "정산 내역 공개 범위 제안드려요", "외주 정산 서류 어디까지 챙기나요?", "9월 정산 후기와 개선점"
        ])
        XCTAssertTrue(viewModel.result.posts.first?.searchMetaText().hasPrefix("팀 게시판 · 익명 · ") == true)
    }

    func testSearchEmptyAndRecentKeywords() async {
        let viewModel = makeContainer().makeBoardSearchViewModel()

        viewModel.query = "없는검색어"
        await viewModel.search()
        guard case .empty = viewModel.state else { return XCTFail("결과가 없으면 empty") }

        viewModel.submit()
        XCTAssertEqual(viewModel.recentKeywords.first, "없는검색어")
        viewModel.removeRecent("없는검색어")
        XCTAssertEqual(viewModel.recentKeywords, MockBoardStore.recentKeywords)

        viewModel.clearRecent()
        viewModel.query = ""
        XCTAssertTrue(viewModel.recentKeywords.isEmpty)
        XCTAssertFalse(viewModel.showsRecent)
    }

    // MARK: 연결

    func testBoardDateLabels() {
        XCTAssertEqual(TSFormat.dayLabel(Date(), now: Date()), "오늘")
        XCTAssertTrue(TSFormat.dayTime(Date(), now: Date()).hasPrefix("오늘 "))
    }
}
