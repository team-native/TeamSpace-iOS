import XCTest
@testable import TeamSpace

/// 은행 계좌 상태 · 새 거래 불러오기 · 입금 계약 연결 (/finance/bank-accounts · /finance/bank-syncs · PATCH matchedProject)
@MainActor
final class BankSyncTests: XCTestCase {
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa, .pm])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer(_ transport: MockTransport = MockTransport(latencyNanoseconds: 0)) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        // 계약 목록(/finance/receipts)은 재정 권한 토큰이 있어야 열려요.
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: transport, tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testLoadShowsAccountStatus() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()
        let account = try XCTUnwrap(viewModel.account)
        XCTAssertEqual(account.title, "NativeOps 운영 계좌 · ******1234")
        XCTAssertEqual(account.connectionText, "은행 연동 준비 중")
        XCTAssertTrue(account.canSync)
        XCTAssertEqual(account.inboundCount, 3)
        XCTAssertEqual(account.outboundCount, 2)
        XCTAssertEqual(viewModel.accountDetailText, "아직 불러온 적 없어요 · 이번 달 입금 3 · 출금 2")
        XCTAssertNil(viewModel.failureNotice)
    }

    func testSyncAddsNewRowsThenReportsNothingNew() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()

        await viewModel.sync()
        XCTAssertEqual(viewModel.toastMessage, "새 거래 1건을 불러왔어요")
        XCTAssertEqual(viewModel.items.first?.id, "106")
        XCTAssertNotNil(viewModel.account?.lastSyncedAt)
        XCTAssertFalse(viewModel.isSyncing)

        await viewModel.sync()
        XCTAssertEqual(viewModel.toastMessage, "새 거래가 없어요")
        XCTAssertEqual(viewModel.items.filter { $0.id == "106" }.count, 1)
    }

    func testSyncFailureShowsServerMessageAndFailureCount() async throws {
        let transport = MockTransport(latencyNanoseconds: 0)
        transport.bankImportStore.failsSync = true
        let viewModel = makeContainer(transport).makeBankImportViewModel(user: fa)
        await viewModel.load()

        await viewModel.sync()

        XCTAssertEqual(viewModel.errorMessage, "은행 연동 업체가 아직 정해지지 않았습니다.", "detail 객체의 message 를 보여줘요")
        XCTAssertEqual(viewModel.failureNotice, "최근 불러오기가 1번 연달아 실패했어요.")
        XCTAssertEqual(viewModel.items.map(\.id), ["105", "104", "103"], "목록은 그대로")
    }

    func testLinkInboundToContractThenConfirm() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()
        await viewModel.loadLinkableContracts()
        let names = try XCTUnwrap(viewModel.linkableContracts.value)
        XCTAssertTrue(names.contains("브랜드 웹 구축"))
        XCTAssertEqual(Set(names).count, names.count, "같은 프로젝트는 한 번만")

        let unmatched = try XCTUnwrap(viewModel.items.first { $0.id == "103" })
        XCTAssertFalse(unmatched.canConfirm)
        viewModel.startLinking(unmatched)
        await viewModel.link(unmatched, to: "브랜드 웹 구축")

        XCTAssertNil(viewModel.linkingItem)
        let linked = try XCTUnwrap(viewModel.items.first { $0.id == "103" })
        XCTAssertEqual(linked.matchedProject, "브랜드 웹 구축")
        XCTAssertEqual(linked.status, .autoMatched, "연결만 하고 확인은 따로")
        XCTAssertTrue(linked.canConfirm)
        XCTAssertEqual(viewModel.toastMessage, "브랜드 웹 구축에 연결했어요. 확인을 눌러 주세요")

        await viewModel.review(linked, .confirm)
        XCTAssertEqual(viewModel.items.first { $0.id == "103" }, nil, "반영 대기로 옮겨졌어요")
        viewModel.filter = .confirmed
        XCTAssertEqual(viewModel.items.map(\.id), ["103"])
    }

    func testLinkRulesAndPermissions() async throws {
        let container = makeContainer()
        let viewModel = container.makeBankImportViewModel(user: fa)
        await viewModel.load()

        let outbound = try XCTUnwrap(viewModel.items.first { $0.id == "104" })
        await viewModel.review(outbound, .link("브랜드 웹 구축"))
        XCTAssertEqual(viewModel.errorMessage, "출금 거래는 수주 계약에 연결할 수 없어요.")

        viewModel.errorMessage = nil
        let inbound = try XCTUnwrap(viewModel.items.first { $0.id == "103" })
        await viewModel.link(inbound, to: "없는 프로젝트")
        XCTAssertEqual(viewModel.errorMessage, "연결할 수주 계약을 찾을 수 없습니다.")
        XCTAssertNil(viewModel.items.first { $0.id == "103" }?.matchedProject)

        let member = container.makeBankImportViewModel(user: leader)
        await member.sync()
        XCTAssertEqual(member.errorMessage, "은행 거래는 FA · 관리자만 관리할 수 있어요.")
    }
}
