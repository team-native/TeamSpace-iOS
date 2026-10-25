import XCTest
@testable import TeamSpace

@MainActor
final class FinanceChartTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func october() throws -> Date {
        try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1)))
    }

    // MARK: 04-5 월별 흐름

    func testMonthlyFlowsMatchFigma() async throws {
        let viewModel = makeContainer().makeMonthlyFlowViewModel(endMonth: try october())

        await viewModel.load()

        let flows = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(flows.map { TSFormat.month($0.month) }, ["4월", "5월", "6월", "7월", "8월", "9월", "10월"])
        let last = try XCTUnwrap(viewModel.selectedFlow)
        XCTAssertEqual(last.income, 7_260_000)
        XCTAssertEqual(last.expense, 3_480_000)
        XCTAssertEqual(TSFormat.signedWon(last.net), "+3,780,000원")
        XCTAssertEqual(viewModel.headline, "수금과 지출의 간격이\n꾸준히 벌어지고 있어요")
    }

    func testSelectingBarChangesInsight() async throws {
        let viewModel = makeContainer().makeMonthlyFlowViewModel(endMonth: try october())
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
        let viewModel = makeContainer().makeFinanceCompositionViewModel(month: try october())

        await viewModel.load()

        let pools = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(pools.map(\.ratio), [40, 30, 30])
        XCTAssertEqual(viewModel.totalRatio, 100)
    }
}
