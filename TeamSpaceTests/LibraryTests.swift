import XCTest
@testable import TeamSpace

@MainActor
final class LibraryTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 06-1 문서함

    func testCategoryCountsMatchFigma() async {
        let viewModel = makeContainer().makeLibraryViewModel()

        await viewModel.load()

        XCTAssertEqual(LibraryFilter.allCases.map { viewModel.count(of: $0) }, [12, 4, 3, 3])
        XCTAssertEqual(viewModel.countText, "12개의 문서")
        XCTAssertEqual(viewModel.filteredDocuments.first?.title, "Native 프로젝트 운영 원칙", "최근 수정한 문서가 위로")
        XCTAssertEqual(viewModel.latestRevision?.title, "프로젝트 운영 원칙")
    }

    func testFilterByCategory() async {
        let viewModel = makeContainer().makeLibraryViewModel()
        await viewModel.load()

        viewModel.filter = .template

        XCTAssertEqual(viewModel.filteredDocuments.map(\.title), ["예산 품의서", "프로젝트 인력 지원 요청서", "정산 요청서"])
        XCTAssertEqual(viewModel.countText, "3개의 문서")
    }

    func testUnknownCategoryDecodesSafely() throws {
        let json = Data(#"{"id":1,"category":"POLICY","title":"t","summary":"s","excerpt":null,"updatedAt":"2026-10-20T00:00:00Z"}"#.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dto = try decoder.decode(LibraryDocumentDTO.self, from: json)

        XCTAssertEqual(dto.toEntity().category, .unknown)
        XCTAssertEqual(LibraryCategory.unknown.badgeTitle, "DOC")
    }

    func testRevisionBannerText() {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 20
        let date = Calendar.current.date(from: components) ?? Date()

        let revision = LibraryRevision(documentId: 1, title: "프로젝트 운영 원칙", effectiveAt: date)

        XCTAssertEqual(revision.bannerText, "프로젝트 운영 원칙 · 10월 20일 시행")
    }

    // MARK: 06-2 문서 검색

    private func makeSearchViewModel(defaultsName: String = #function) -> LibrarySearchViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let defaults = UserDefaults(suiteName: "test.library.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsRecentSearchRepository.libraryKey)
        let container = DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            recentSearchRepository: UserDefaultsRecentSearchRepository(
                defaults: defaults,
                seed: MockLibraryFixture.recentKeywords
            )
        )
        return container.makeLibrarySearchViewModel()
    }

    func testSearchMatchesFigma() async {
        let viewModel = makeSearchViewModel()
        viewModel.query = "정산"

        await viewModel.search()

        XCTAssertEqual(viewModel.results.map(\.title), ["외주 수금 및 풀 배분 기준", "외주 프로젝트 진행 가이드", "정산 요청서"])
        XCTAssertEqual(viewModel.results.map(\.excerpt), ["…배분과 정산 방식을 정리해요", "…납품 후 정산 요청 순서", "프로젝트 종료 후 정산을 요청하는 양식"])
        XCTAssertEqual(viewModel.resultTitle, "검색 결과 3")
    }

    func testEmptyResultAndBlankQuery() async {
        let viewModel = makeSearchViewModel()

        viewModel.query = "없는검색어"
        await viewModel.search()
        guard case .empty = viewModel.state else { return XCTFail("결과가 없으면 empty") }
        XCTAssertEqual(viewModel.emptyMessage, "‘없는검색어’에 맞는 문서가 없어요. 다른 검색어로 찾아보세요.")

        viewModel.query = "   "
        await viewModel.search()
        guard case .idle = viewModel.state else { return XCTFail("빈 검색어는 검색하지 않아요") }
    }

    func testRecentKeywordsOrderAndLimit() {
        let viewModel = makeSearchViewModel()
        XCTAssertEqual(viewModel.recentKeywords, ["수금", "품의서", "회의"])

        viewModel.selectRecent("회의")
        XCTAssertEqual(viewModel.recentKeywords, ["회의", "수금", "품의서"], "같은 검색어는 맨 앞으로 한 번만")

        for keyword in ["a", "b", "c", "d"] {
            viewModel.query = keyword
            viewModel.submit()
        }
        XCTAssertEqual(viewModel.recentKeywords, ["d", "c", "b", "a", "회의"])
        XCTAssertEqual(viewModel.query, "d")
    }
}
