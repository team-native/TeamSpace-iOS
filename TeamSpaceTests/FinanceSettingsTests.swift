import XCTest
@testable import TeamSpace

/// 재무 요약 설정 [FA · Admin] (GET · PATCH /admin/finance/settings)
@MainActor
final class FinanceSettingsTests: XCTestCase {
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa, .pm])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testLoadShowsPools() async throws {
        let viewModel = makeContainer().makeFinanceSettingsViewModel(user: fa)
        await viewModel.load()
        XCTAssertEqual(viewModel.rows.map(\.pool.label), ["운영풀", "적립풀", "배당풀"])
        XCTAssertEqual(viewModel.rows.map(\.ratioText), ["40", "30", "30"])
        XCTAssertEqual(viewModel.ratioText, "합계 100%")
        XCTAssertEqual(viewModel.amountTotalText, "모든 풀 8,900,000원")
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)
    }

    func testSaveUpdatesSummaryPools() async throws {
        let container = makeContainer()
        let viewModel = container.makeFinanceSettingsViewModel(user: fa)
        await viewModel.load()
        viewModel.rows[0].ratioText = "60"
        viewModel.rows[2].ratioText = "10"
        viewModel.rows[0].amountText = "4,000,000"
        XCTAssertTrue(viewModel.canSave)

        await viewModel.save()

        XCTAssertEqual(viewModel.toastMessage, "재무 설정을 저장했어요")
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertEqual(viewModel.rows.first?.pool.color, "#3182f6", "웹 색은 그대로")
        let overview = container.makeFinanceViewModel(user: fa)
        await overview.load()
        let pools = try XCTUnwrap(overview.state.value?.pools)
        XCTAssertEqual(pools.map(\.ratio), [60, 30, 10])
        XCTAssertEqual(pools.first?.amount, 4_000_000)
    }

    func testRatioMustSumTo100AndResetRestores() async throws {
        let viewModel = makeContainer().makeFinanceSettingsViewModel(user: fa)
        await viewModel.load()
        viewModel.rows[0].ratioText = "50"
        XCTAssertEqual(viewModel.ratioText, "합계 110% — 100%가 되게 해 주세요")
        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)

        viewModel.rows[1].amountText = ""
        XCTAssertFalse(viewModel.canSave, "빈 금액은 저장할 수 없어요")

        viewModel.reset()
        XCTAssertEqual(viewModel.rows.map(\.ratioText), ["40", "30", "30"])
        XCTAssertFalse(viewModel.hasChanges)
    }

    func testEmptySettingsFallBackToServerDefaults() async throws {
        let json = #"{"pools":[],"flow":[],"notices":[]}"#
        let dto = try JSONDecoder().decode(ServerFinanceSettingsDTO.self, from: Data(json.utf8))
        XCTAssertTrue(dto.pools.isEmpty)
        XCTAssertEqual(FinanceSettingsPool.defaults.map(\.ratio), [60, 30, 10])

        let pool = try JSONDecoder().decode(ServerFinanceSettingsDTO.Pool.self, from: Data(#"{"id":"reserve","amount":"1,000","ratio":30}"#.utf8))
        XCTAssertEqual(pool.amount, 1_000)
        XCTAssertEqual(pool.label, "reserve", "이름이 없으면 id 로")
        let body = try XCTUnwrap(String(data: JSONEncoder().encode(ServerFinanceSettingsPatchDTO(pools: [pool])), encoding: .utf8))
        XCTAssertFalse(body.contains("flow"), "pools 만 보내요")
    }

    func testOnlyFAOrAdminCanOpen() async throws {
        let viewModel = makeContainer().makeFinanceSettingsViewModel(user: leader)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("FA · 관리자만 열 수 있어요") }
        XCTAssertTrue(viewModel.rows.isEmpty)
    }
}
