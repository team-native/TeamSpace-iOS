import XCTest
@testable import TeamSpace

@MainActor
final class FinanceViewModelTests: XCTestCase {
    private func makeViewModel(roles: [UserRole] = [.member], now: Date = Date()) -> FinanceViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return FinanceViewModel(
            user: AuthUser(id: 1, name: "옥물결", roles: roles),
            fetchFinanceOverviewUseCase: DIContainer(apiClient: client, tokenStorage: tokenStorage).fetchFinanceOverviewUseCase,
            now: now
        )
    }

    private func october2026() -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 25)) ?? Date()
    }

    func testOverviewMatchesFigmaInOctober() async throws {
        let viewModel = makeViewModel(now: october2026())

        await viewModel.load()

        let overview = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(viewModel.monthTitle, "2026년 10월")
        XCTAssertEqual(overview.collectedAmount, 8_900_000)
        XCTAssertEqual(overview.pools.map(\.kind), [.operation, .reserve, .dividend])
        XCTAssertEqual(overview.pools.map(\.amount), [3_560_000, 2_670_000, 2_670_000])
        XCTAssertEqual(overview.availableAmount, 3_560_000)
        XCTAssertTrue(overview.isDemo)
    }

    func testSelectingAnotherMonthReloads() async throws {
        let viewModel = makeViewModel(now: october2026())
        await viewModel.load()
        let september = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1)))

        await viewModel.selectMonth(september)

        XCTAssertEqual(viewModel.monthTitle, "2026년 9월")
        XCTAssertFalse(viewModel.isPeriodPickerPresented)
        XCTAssertNotEqual(viewModel.state.value?.collectedAmount, 8_900_000)
    }

    func testPermissionNoticeByRole() {
        XCTAssertEqual(makeViewModel(roles: [.member]).permissionNotice, "재정 정보는 권한별로 공개 범위가 달라요 · 내 권한: 구성원")
        XCTAssertFalse(makeViewModel(roles: [.member]).canViewDetail)
        XCTAssertTrue(makeViewModel(roles: [.fa]).canViewDetail)
    }

    func testPermissionEnum() {
        let member = AuthUser(id: 1, name: "구성원", roles: [.member])
        let pm = AuthUser(id: 2, name: "PM", roles: [.member, .pm])
        XCTAssertTrue(member.can(.viewFinanceSummary))
        XCTAssertFalse(member.can(.approveDocument))
        XCTAssertTrue(pm.can(.manageProject))
        XCTAssertFalse(pm.can(.viewFinanceDetail))
    }
}
