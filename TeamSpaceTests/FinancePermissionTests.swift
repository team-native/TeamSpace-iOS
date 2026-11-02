import XCTest
@testable import TeamSpace

@MainActor
final class FinancePermissionTests: XCTestCase {
    private let member = AuthUser(id: 1, name: "옥물결", roles: [.member])
    private let fa = AuthUser(id: 2, name: "김민준", roles: [.fa])

    /// FA 로 로그인했으면 Mock 서버가 금액을 보여줘요.
    private func makeContainer(asFA: Bool) throws -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let token = asFA ? MockTransport.faToken : "mock-access-token"
        try tokenStorage.save(AuthToken(accessToken: token, refreshToken: "r"), persistent: false)
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 04-9 프로젝트별 금액

    func testFASeesAmountsMatchingFigma() async throws {
        let viewModel = try makeContainer(asFA: true).makeProjectAmountsViewModel(year: 2026, user: fa)

        await viewModel.load()

        let summary = try XCTUnwrap(viewModel.state.value)
        XCTAssertFalse(viewModel.isAmountHidden)
        XCTAssertEqual(summary.totalContractAmount, 23_000_000, "수금 내역을 프로젝트별로 더해요")
        XCTAssertEqual(summary.totalPaidAmount, 20_500_000)
        XCTAssertEqual(summary.totalUnpaidAmount, 2_500_000)
        XCTAssertEqual(viewModel.visibleProjects.count, 4)
        XCTAssertEqual(viewModel.hiddenCount, 3)
        XCTAssertEqual(viewModel.visibleProjects.first?.name, "관리자 도구 개발", "최근 수금일 순")
        XCTAssertEqual(viewModel.visibleProjects.first?.paidPercent, 0)
    }

    func testFilterCompleted() async throws {
        let viewModel = try makeContainer(asFA: true).makeProjectAmountsViewModel(year: 2026, user: fa)
        await viewModel.load()

        viewModel.filter = .completed

        XCTAssertTrue(viewModel.visibleProjects.allSatisfy { $0.status == .completed })
        XCTAssertTrue(viewModel.visibleProjects.allSatisfy { $0.unpaidAmount == 0 })
    }

    // MARK: 04-8 권한 없음

    func testMemberIsForbidden() async throws {
        let viewModel = try makeContainer(asFA: false).makeProjectAmountsViewModel(year: 2026, user: member)

        await viewModel.load()

        XCTAssertTrue(viewModel.isAmountHidden)
        guard case .forbidden = viewModel.state else { return XCTFail("서버는 재정 권한이 없으면 403: \(viewModel.state)") }
    }

    // MARK: 04-7 재정 제한 권한

    func testAccessSummaryForMember() async throws {
        let viewModel = try makeContainer(asFA: false).makeFinanceAccessViewModel(user: member, year: 2026)

        await viewModel.load()

        XCTAssertEqual(viewModel.scopeBadge, "일반 구성원 · 공개 요약")
        XCTAssertTrue(viewModel.canRequestAccess)
        let ledger = try XCTUnwrap(viewModel.state.value, "수금 내역 대신 요약의 누적 수주를 보여줘요")
        XCTAssertEqual(ledger.totalAmount, 23_000_000)
        XCTAssertTrue(ledger.contracts.isEmpty)
        XCTAssertNil(viewModel.latestCollected, "개별 수주는 비공개")
        XCTAssertEqual(viewModel.totalTitle, "누적 수주")
    }

    // MARK: 04-1 구성원도 요약을 봐요

    func testMemberSeesOverview() async throws {
        let container = try makeContainer(asFA: false)
        let viewModel = container.makeFinanceViewModel(user: member)

        await viewModel.load()

        let overview = try XCTUnwrap(viewModel.state.value, "서버 /finance/summary 는 모두에게 열려 있어요")
        XCTAssertEqual(overview.availableAmount, 3_560_000)
        XCTAssertEqual(overview.income.amount, 7_260_000)
        XCTAssertFalse(viewModel.canViewDetail)
    }

    func testOverviewOfPastMonthUsesServerMonth() async throws {
        let viewModel = try makeContainer(asFA: false).makeFinanceViewModel(user: member)
        await viewModel.load()
        let calendar = Calendar.current
        let previous = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: viewModel.selectedMonth))

        await viewModel.selectMonth(previous)

        let overview = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(overview.income.amount, 7_260_000 * 80 / 96 / 10_000 * 10_000, "month=YYYY-MM 로 그 달 수입")
        XCTAssertEqual(overview.expense.amount, 3_480_000 * 46 / 50 / 10_000 * 10_000)
    }

    func testAccessSummaryForFA() async throws {
        let viewModel = try makeContainer(asFA: true).makeFinanceAccessViewModel(user: fa, year: 2026)
        await viewModel.load()
        XCTAssertEqual(viewModel.state.value?.totalAmount, 23_000_000)
        XCTAssertEqual(viewModel.latestCollected?.name, "BRIDGE")
        XCTAssertEqual(viewModel.totalTitle, "2026년 누적 수주 · 표본")
    }

    func testFAHasNoRequestButton() throws {
        let viewModel = try makeContainer(asFA: true).makeFinanceAccessViewModel(user: fa, year: 2026)

        XCTAssertFalse(viewModel.canRequestAccess)
        XCTAssertEqual(viewModel.scopeBadge, "FA · 전체 열람")
    }
}
