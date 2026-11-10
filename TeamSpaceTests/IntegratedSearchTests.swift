import XCTest
@testable import TeamSpace

@MainActor
final class IntegratedSearchTests: XCTestCase {
    private func makeViewModel() -> IntegratedSearchViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeIntegratedSearchViewModel()
    }

    // MARK: 13 통합 검색 결과

    func testSearchGroupsAndCounts() async {
        let viewModel = makeViewModel()
        viewModel.query = "Book-on"
        await viewModel.search()

        XCTAssertEqual(viewModel.title, "Book-on 검색 결과")
        XCTAssertEqual(viewModel.count(of: .all), 6)
        XCTAssertEqual(viewModel.count(of: .documents), 2)
        XCTAssertEqual(viewModel.count(of: .posts), 2, "공개 게시글 + 운영 제안")
        XCTAssertEqual(viewModel.summaryText, "총 6개 · 관련도순")
        XCTAssertEqual(viewModel.sections.map(\.title), ["문서·규정", "프로젝트", "팀원", "공개 게시글·운영 제안"])

        viewModel.filter = .projects
        XCTAssertEqual(viewModel.sections.map(\.title), ["프로젝트"])
        XCTAssertEqual(viewModel.sections.first?.hits.first?.route, .projectDetail(id: "1"))
    }

    func testHitTextAndRoutes() async {
        let viewModel = makeViewModel()
        viewModel.query = "Book-on"
        await viewModel.search()
        let hits = viewModel.sections.flatMap(\.hits)

        let rule = hits.first { $0.title.hasPrefix("프로젝트 운영 원칙") }
        XCTAssertEqual(rule?.badgeTitle, "운영 규정")
        XCTAssertEqual(rule?.linkTitle, "규정 본문 보기")
        XCTAssertEqual(rule?.route, .ruleDetail(id: "project-principles"), "문서는 href 의 slug 로 열어요")

        let document = hits.first { $0.title == "Book-on QA 체크리스트" }
        XCTAssertEqual(document?.version, "2", "숫자 버전도 읽어요")
        XCTAssertNotNil(document?.createdAt, "소수점 초가 있는 날짜도 읽어요")
        XCTAssertTrue(document?.metaText.hasPrefix("v2 · ") == true)

        let proposal = hits.first { $0.category == .proposals }
        XCTAssertEqual(proposal?.route, .proposalDetail(id: 11))
        XCTAssertTrue(proposal?.metaText.contains("추천 18") == true)
        XCTAssertEqual(hits.first { $0.category == .people }?.route, .memberDetail(id: "1"))
    }

    // MARK: 14-2 결과 없음 · 짧은 검색어

    func testEmptyAndShortQuery() async {
        let viewModel = makeViewModel()
        viewModel.query = "가"
        await viewModel.search()
        XCTAssertTrue(viewModel.isQueryTooShort)
        guard case .idle = viewModel.state else { return XCTFail("1자는 검색하지 않아요") }

        viewModel.query = "없는검색어"
        await viewModel.search()
        guard case .empty = viewModel.state else { return XCTFail("결과가 없으면 14-2") }
    }

    func testFilteredEmptyAndReset() async {
        let viewModel = makeViewModel()
        viewModel.query = "회의 기록"
        await viewModel.search()
        viewModel.filter = .people
        XCTAssertTrue(viewModel.isFilteredEmpty)

        viewModel.resetFilter()
        XCTAssertFalse(viewModel.isFilteredEmpty)
        XCTAssertEqual(viewModel.sections.map(\.title), ["공개 게시글·운영 제안"])
    }

    // MARK: COMMON-02 목록 페이지네이션

    private func makePagedViewModel(pageSize: Int) -> IntegratedSearchViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return IntegratedSearchViewModel(
            searchAllUseCase: SearchAllUseCase(searchRepository: SearchRepositoryImpl(client: client), pageSize: pageSize)
        )
    }

    func testLoadMoreAppendsNextPages() async {
        let viewModel = makePagedViewModel(pageSize: 4)
        viewModel.query = "Book-on"
        await viewModel.search()

        XCTAssertEqual(viewModel.sections.flatMap(\.hits).count, 4)
        XCTAssertEqual(viewModel.count(of: .all), 6, "개수는 처음부터 전체 기준")
        XCTAssertTrue(viewModel.paging.hasMore)

        await viewModel.loadMore()
        XCTAssertEqual(viewModel.sections.flatMap(\.hits).count, 6)
        XCTAssertEqual(viewModel.sections.map(\.title), ["문서·규정", "프로젝트", "팀원", "공개 게시글·운영 제안"])
        XCTAssertFalse(viewModel.paging.hasMore)
    }

    func testClearQueryStopsPaging() async {
        let viewModel = makePagedViewModel(pageSize: 2)
        viewModel.query = "Book-on"
        await viewModel.search()
        XCTAssertTrue(viewModel.paging.hasMore)

        viewModel.clearQuery()
        XCTAssertFalse(viewModel.paging.hasMore)
        await viewModel.loadMore()
        XCTAssertNil(viewModel.state.value, "검색어를 지우면 다음 페이지도 부르지 않아요")
    }

    func testPagingStateRetriesSameCursorAfterFailure() {
        var paging = PagingState(nextCursor: "50")
        XCTAssertEqual(paging.begin(), "50")
        XCTAssertNil(paging.begin(), "불러오는 중에는 또 부르지 않아요")
        paging.fail()
        XCTAssertTrue(paging.didFail)
        XCTAssertEqual(paging.begin(), "50", "다시 불러오기는 같은 커서로")
        paging.finish(nextCursor: nil)
        XCTAssertFalse(paging.hasMore)
    }
}
