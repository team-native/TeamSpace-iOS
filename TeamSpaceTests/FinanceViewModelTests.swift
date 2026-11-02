import XCTest
@testable import TeamSpace

@MainActor
final class FinanceViewModelTests: XCTestCase {
    private func makeViewModel(roles: [UserRole] = [.member], now: Date = Date()) -> FinanceViewModel {
        let tokenStorage = InMemoryTokenStorage()
        // 서버처럼 재정 API 는 재정 권한(FA)이 있어야 열려요.
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
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

    func testOverviewReadsServerSummary() async throws {
        let viewModel = makeViewModel(now: Date())

        await viewModel.load()

        let overview = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(overview.collectedAmount, 7_260_000, "summary.monthlyRevenue")
        XCTAssertEqual(overview.expense.amount, 3_480_000, "summary.monthlyExpense")
        XCTAssertEqual(overview.pools.map(\.kind), [.operation, .reserve, .dividend])
        XCTAssertEqual(overview.pools.map(\.amount), [3_560_000, 2_670_000, 2_670_000])
        XCTAssertEqual(overview.availableAmount, 3_560_000)
        XCTAssertFalse(overview.isDemo)
        XCTAssertEqual(overview.changeRate, 20, "지난달 6,050,000 → 7,260,000")
    }

    func testSelectingAnotherMonthUsesServerFlow() async throws {
        let viewModel = makeViewModel(now: Date())
        await viewModel.load()
        let previous = try XCTUnwrap(Calendar.current.date(byAdding: .month, value: -1, to: Calendar.current.startOfMonth(for: Date())))

        await viewModel.selectMonth(previous)

        XCTAssertFalse(viewModel.isPeriodPickerPresented)
        XCTAssertEqual(viewModel.state.value?.collectedAmount, 6_050_000, "지난 달은 서버 flow 의 수입")
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
