import XCTest
@testable import TeamSpace

@MainActor
final class RuleTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 09-1 규칙 · 제도

    func testRuleListPutsUrgentRuleFirst() async {
        let viewModel = makeContainer().makeRuleListViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.urgentRule?.id, 1, "읽음 확인 안 한 중요 개정")
        XCTAssertEqual(viewModel.rules.map(\.id), [1, 5, 13, 8, 12], "중요 개정 → 시행 예정 → 최근 개정순")
        XCTAssertEqual(viewModel.urgentRule?.status, .scheduled)
    }

    func testRuleListFilters() async {
        let viewModel = makeContainer().makeRuleListViewModel()
        await viewModel.load()

        viewModel.category = .operation
        XCTAssertEqual(viewModel.rules.map(\.id), [5, 12])

        viewModel.category = nil
        viewModel.statusFilter = .scheduled
        XCTAssertEqual(viewModel.rules.map(\.id), [1])

        viewModel.statusFilter = .recentlyRevised
        XCTAssertEqual(viewModel.rules.map(\.id), [1, 5, 13])

        viewModel.statusFilter = .all
        viewModel.query = "보안"
        XCTAssertEqual(viewModel.rules.map(\.id), [12])
    }

    // MARK: 09-2 문서 상세 · 규칙

    func testRuleDetailAcknowledgeClearsUrgentRule() async throws {
        let container = makeContainer()
        let detail = container.makeRuleDetailViewModel(ruleId: 1)
        await detail.load()

        let loaded = try XCTUnwrap(detail.detail)
        XCTAssertEqual(loaded.articles.map(\.number), [1, 2, 3, 4])
        XCTAssertEqual(loaded.articles.filter(\.isRevised).map(\.number), [2])
        XCTAssertEqual(detail.readingText, "읽어보는 중...")
        XCTAssertFalse(detail.isAcknowledged)

        await detail.acknowledge()
        XCTAssertTrue(detail.isAcknowledged)
        XCTAssertTrue(detail.readingText.hasSuffix("읽음 확인 완료"))
        XCTAssertEqual(detail.detail?.rule.isAcknowledged, true)

        let list = container.makeRuleListViewModel()
        await list.load()
        XCTAssertNil(list.urgentRule)
        XCTAssertEqual(list.rules.first?.id, 1, "읽은 뒤에도 시행 예정이라 맨 위")
    }

    // MARK: 연결

    func testRuleEntryRoutes() {
        XCTAssertEqual(NotificationType.rule.targetRoute, .rules)
        XCTAssertEqual(NotificationType.schedule.targetRoute, .workspaceSchedules)
    }
}
