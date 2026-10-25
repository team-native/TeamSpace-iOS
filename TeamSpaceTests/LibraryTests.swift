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
}
