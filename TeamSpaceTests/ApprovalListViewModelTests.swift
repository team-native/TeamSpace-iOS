import XCTest
@testable import TeamSpace

@MainActor
final class ApprovalListViewModelTests: XCTestCase {
    private func makeViewModel() -> ApprovalListViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeApprovalListViewModel()
    }

    // MARK: 05-1 내가 올린 결재

    func testMySummaryCountsMatchFigma() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.summaryStatuses.map { viewModel.count(of: $0) }, [1, 1, 1, 3, 1])
        XCTAssertEqual(viewModel.myTotalCount, 7)
        XCTAssertEqual(viewModel.recentMine.count, 4)
        XCTAssertEqual(viewModel.recentMine.first?.title, "Book-on 테스트 기기 구매", "가장 최근 결재가 위로")
        XCTAssertEqual(viewModel.headline, "필요한 안건을\n결재로 올려요.")
    }

    // MARK: 05-2 받은 결재

    func testReceivedWaitingAndHandled() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.tab = .received

        XCTAssertEqual(viewModel.waitingReceived.map(\.title), ["Book-on 프로젝트 인력 지원", "디자인 리뷰 외부 장소 대관"])
        XCTAssertEqual(viewModel.title(for: .received), "받은 결재 2")
        XCTAssertEqual(viewModel.headline, "검토를 기다리는\n요청이 2건 있어요.")
        XCTAssertTrue(viewModel.handledThisMonth().allSatisfy { $0.status.isHandled })
    }

    func testMetaText() {
        let draft = ApprovalItem(
            id: 1, kind: .expense, title: "워크숍", amount: nil, status: .draft,
            requesterName: "옥물결", requesterDepartment: "Design", summary: nil, updatedAt: Date()
        )
        XCTAssertEqual(draft.metaText, "비용 · 임시 저장")
    }
}
