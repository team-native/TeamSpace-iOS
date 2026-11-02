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
        guard case .forbidden = viewModel.state else { return XCTFail("공개 요약 API 가 없어 403 이에요: \(viewModel.state)") }
    }

    func testAccessSummaryForFA() async throws {
        let viewModel = try makeContainer(asFA: true).makeFinanceAccessViewModel(user: fa, year: 2026)
        await viewModel.load()
        XCTAssertEqual(viewModel.state.value?.totalAmount, 23_000_000)
        XCTAssertEqual(viewModel.latestCollected?.name, "BRIDGE")
    }

    func testFAHasNoRequestButton() throws {
        let viewModel = try makeContainer(asFA: true).makeFinanceAccessViewModel(user: fa, year: 2026)

        XCTAssertFalse(viewModel.canRequestAccess)
        XCTAssertEqual(viewModel.scopeBadge, "FA · 전체 열람")
    }
}
