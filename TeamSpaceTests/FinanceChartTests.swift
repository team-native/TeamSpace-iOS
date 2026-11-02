import XCTest
@testable import TeamSpace

@MainActor
final class FinanceChartTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        // 서버처럼 재정 API 는 재정 권한(FA)이 있어야 열려요.
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    /// 서버 flow 는 이번 달까지라 오늘 기준으로 확인해요.
    private func thisMonth() -> Date {
        Calendar.current.startOfMonth(for: Date())
    }

    // MARK: 04-5 월별 흐름

    func testMonthlyFlowsMatchFigma() async throws {
        let viewModel = makeContainer().makeMonthlyFlowViewModel(endMonth: thisMonth())

        await viewModel.load()

        let flows = try XCTUnwrap(viewModel.state.value)
        let expected = (0..<7).compactMap { Calendar.current.date(byAdding: .month, value: $0 - 6, to: thisMonth()) }
        XCTAssertEqual(flows.map { TSFormat.month($0.month) }, expected.map { TSFormat.month($0) }, "최근 7개월, 오래된 달부터")
        let last = try XCTUnwrap(viewModel.selectedFlow)
        XCTAssertEqual(last.income, 7_260_000)
        XCTAssertEqual(last.expense, 3_480_000)
        XCTAssertEqual(TSFormat.signedWon(last.net), "+3,780,000원")
        XCTAssertEqual(viewModel.headline, "수금과 지출의 간격이\n꾸준히 벌어지고 있어요")
    }

    func testSelectingBarChangesInsight() async throws {
        let viewModel = makeContainer().makeMonthlyFlowViewModel(endMonth: thisMonth())
        await viewModel.load()
        let first = try XCTUnwrap(viewModel.state.value?.first)

        viewModel.select(first)

        XCTAssertEqual(viewModel.selectedFlow, first)
    }

    func testFlowTrend() {
        let now = Date()
        let narrowing = [
            MonthlyFlow(month: now, income: 100, expense: 10),
            MonthlyFlow(month: now.addingTimeInterval(1), income: 100, expense: 90)
        ]
        XCTAssertEqual(FlowTrend.of(narrowing), .narrowing)
        XCTAssertEqual(FlowTrend.of([]), .steady)
    }

    // MARK: 04-6 돈의 구성

    func testCompositionUsesPoolRatios() async throws {
        let viewModel = makeContainer().makeFinanceCompositionViewModel(month: thisMonth())

        await viewModel.load()

        let pools = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(pools.map(\.ratio), [40, 30, 30])
        XCTAssertEqual(viewModel.totalRatio, 100)
    }
}
