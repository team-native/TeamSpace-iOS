import XCTest
@testable import TeamSpace

@MainActor
final class ContractLedgerTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
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
        XCTAssertEqual(viewModel.state.value?.totalAmount, 48_300_000)
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
        XCTAssertEqual(detail.steps.map(\.title), ["계약", "착수", "납품", "입금 완료"])
        XCTAssertTrue(detail.steps.allSatisfy(\.isDone))
        XCTAssertEqual(detail.pools.map(\.amount), [1_440_000, 1_080_000, 1_080_000])
        XCTAssertTrue(viewModel.amountCaption(detail).hasSuffix("입금 확인 · 부가세 별도"))
        XCTAssertEqual(detail.steps.first?.caption.hasSuffix("· 계약서 서명"), true)
    }

    func testUnknownContractIsNotFound() async {
        let viewModel = makeContainer().makeContractDetailViewModel(contractId: 999)

        await viewModel.load()

        guard case .failed(let error) = viewModel.state, case .notFound = error as? AppError else {
            return XCTFail("없는 수주는 404 여야 해요: \(viewModel.state)")
        }
    }
}
