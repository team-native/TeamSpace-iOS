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
        XCTAssertEqual(summary.totalContractAmount, 28_400_000)
        XCTAssertEqual(summary.totalPaidAmount, 19_860_000)
        XCTAssertEqual(summary.totalUnpaidAmount, 8_540_000)
        XCTAssertEqual(viewModel.visibleProjects.count, 4)
        XCTAssertEqual(viewModel.hiddenCount, 5, "Figma: 외 5개 프로젝트 보기")
        XCTAssertEqual(viewModel.visibleProjects.first?.paidPercent, 50)
    }

    func testFilterCompleted() async throws {
        let viewModel = try makeContainer(asFA: true).makeProjectAmountsViewModel(year: 2026, user: fa)
        await viewModel.load()

        viewModel.filter = .completed

        XCTAssertTrue(viewModel.visibleProjects.allSatisfy { $0.status == .completed })
        XCTAssertTrue(viewModel.visibleProjects.allSatisfy { $0.unpaidAmount == 0 })
    }

    // MARK: 04-8 권한 없음

    func testMemberGetsMaskedAmounts() async throws {
        let viewModel = try makeContainer(asFA: false).makeProjectAmountsViewModel(year: 2026, user: member)

        await viewModel.load()

        let summary = try XCTUnwrap(viewModel.state.value)
        XCTAssertTrue(viewModel.isAmountHidden)
        XCTAssertTrue(summary.isMasked, "서버가 금액을 null 로 보내요")
        XCTAssertTrue(summary.projects.allSatisfy { $0.contractAmount == nil })
        XCTAssertEqual(summary.monthNewContracts, 2)
        XCTAssertEqual(summary.monthDeposits, 3)
    }

    // MARK: 04-7 재정 제한 권한

    func testAccessSummaryForMember() async throws {
        let viewModel = try makeContainer(asFA: false).makeFinanceAccessViewModel(user: member, year: 2026)

        await viewModel.load()

        XCTAssertEqual(viewModel.scopeBadge, "일반 구성원 · 공개 요약")
        XCTAssertTrue(viewModel.canRequestAccess)
        XCTAssertEqual(viewModel.state.value?.totalAmount, 48_300_000)
        XCTAssertEqual(viewModel.latestCollected?.name, "BRIDGE")
    }

    func testFAHasNoRequestButton() throws {
        let viewModel = try makeContainer(asFA: true).makeFinanceAccessViewModel(user: fa, year: 2026)

        XCTAssertFalse(viewModel.canRequestAccess)
        XCTAssertEqual(viewModel.scopeBadge, "FA · 전체 열람")
    }
}
