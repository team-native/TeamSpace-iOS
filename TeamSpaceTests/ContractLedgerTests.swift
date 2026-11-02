import XCTest
@testable import TeamSpace

@MainActor
final class ContractLedgerTests: XCTestCase {
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

    // MARK: 04-3 수금 내역

    func testLedgerGroupsByMonthNewestFirst() async {
        let viewModel = makeContainer().makeContractLedgerViewModel(year: 2026)

        await viewModel.load()

        XCTAssertEqual(viewModel.totalTitle, "2026년 누적 수주")
        XCTAssertEqual(viewModel.state.value?.totalAmount, 23_000_000, "서버 totals.totalOrder")
        XCTAssertEqual(viewModel.groups.map { viewModel.groupTitle($0) }, ["10월", "9월", "8월"])
        XCTAssertEqual(viewModel.groups.first?.contracts.map(\.name), ["CAMPUS", "BRIDGE", "MOTION"])
    }

    func testFilterScheduledOnly() async {
        let viewModel = makeContainer().makeContractLedgerViewModel(year: 2026)
        await viewModel.load()

        viewModel.filter = .scheduled

        let contracts = viewModel.groups.flatMap(\.contracts)
        XCTAssertEqual(contracts.map(\.name), ["CAMPUS"])
    }

    func testSortByAmount() async {
        let viewModel = makeContainer().makeContractLedgerViewModel(year: 2026)
        await viewModel.load()

        viewModel.sort = .amount

        XCTAssertEqual(viewModel.groups.count, 1)
        XCTAssertEqual(viewModel.groups.first?.contracts.first?.name, "HELLO")
    }

    // MARK: 04-2 수주 상세

    func testContractDetailFromFigma() async throws {
        let viewModel = makeContainer().makeContractDetailViewModel(contractId: 1)

        await viewModel.load()

        let detail = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(detail.contract.name, "BRIDGE")
        XCTAssertEqual(detail.steps.map(\.title), ["상담", "견적", "계약", "제작", "납품", "수금"], "프런트 CONTRACT_STEPS")
        XCTAssertTrue(detail.steps.allSatisfy(\.isDone))
        XCTAssertEqual(detail.pools.map(\.amount), [2_160_000, 1_080_000, 360_000], "split 운영 60 · 적립 30 · 배당 10")
        XCTAssertEqual(detail.managerName, "이시우")
        XCTAssertEqual(detail.memberCount, 5)
        XCTAssertEqual(detail.documentName, "BRIDGE 계약서.pdf")
        XCTAssertTrue(viewModel.amountCaption(detail).hasSuffix("입금 확인"))
        XCTAssertEqual(detail.steps[2].caption.hasSuffix("· 계약서 서명"), true, "\"09.02 계약서 서명\" → 날짜 + 메모")
        XCTAssertEqual(detail.steps.first?.caption, "08.20")
    }

    func testUnknownContractIsNotFound() async {
        let viewModel = makeContainer().makeContractDetailViewModel(contractId: 999)

        await viewModel.load()

        guard case .failed(let error) = viewModel.state, case .notFound = error as? AppError else {
            return XCTFail("없는 수주는 404 여야 해요: \(viewModel.state)")
        }
    }

    func testContractWithoutContractInfoShowsReceiptOnly() async throws {
        let viewModel = makeContainer().makeContractDetailViewModel(contractId: 7)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.state.value, "계약 정보가 없으면(404) 수금 내용만 보여줘요")
        XCTAssertEqual(detail.contract.name, "CAMPUS")
        XCTAssertEqual(detail.contract.status, .scheduled)
        XCTAssertTrue(detail.steps.isEmpty)
        XCTAssertTrue(detail.pools.isEmpty)
    }

    func testMemberIsForbidden() async {
        let tokenStorage = InMemoryTokenStorage()
        try? tokenStorage.save(AuthToken(accessToken: "mock-access-token", refreshToken: "r"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        let viewModel = DIContainer(apiClient: client, tokenStorage: tokenStorage).makeContractLedgerViewModel(year: 2026)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("서버는 재정 권한이 없으면 403: \(viewModel.state)") }
    }
}
