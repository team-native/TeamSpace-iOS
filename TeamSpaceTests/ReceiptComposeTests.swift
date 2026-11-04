import XCTest
@testable import TeamSpace

/// 수금 등록 · 수정 [FA · Admin] (POST /admin/finance/receipts · PATCH /admin/finance/receipts/{id})
@MainActor
final class ReceiptComposeTests: XCTestCase {
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa, .pm])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func thisYear(month: Int, day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    func testRegisterReceiptShowsInLedger() async throws {
        let container = makeContainer()
        let compose = container.makeReceiptComposeViewModel(user: fa)
        XCTAssertEqual(compose.screenTitle, "수금 등록")
        XCTAssertFalse(compose.canSubmit)

        compose.draft.client = "LUMEN"
        compose.draft.project = "예약 앱 MVP"
        compose.draft.amountText = "4,500,000"
        compose.draft.status = .billed
        compose.draft.date = thisYear(month: 11, day: 3)
        XCTAssertEqual(compose.amountPreview, "4,500,000원")
        XCTAssertTrue(compose.canSubmit)

        await compose.submit()

        XCTAssertTrue(compose.didSave)
        XCTAssertNil(compose.errorMessage)
        let id = try XCTUnwrap(compose.savedId)
        let year = Calendar.current.component(.year, from: Date())
        let ledger = container.makeContractLedgerViewModel(year: year)
        await ledger.load()
        let row = try XCTUnwrap(ledger.state.value?.contracts.first { $0.id == id })
        XCTAssertEqual(row.name, "LUMEN")
        XCTAssertEqual(row.title, "예약 앱 MVP")
        XCTAssertEqual(row.amount, 4_500_000)
        XCTAssertEqual(row.status, .scheduled, "청구 완료는 앱에서 입금 전으로 보여요")
    }

    func testEditSendsOnlyChangedFields() async throws {
        let container = makeContainer()
        let detail = container.makeContractDetailViewModel(contractId: 7)
        await detail.load()
        let contract = try XCTUnwrap(detail.state.value?.contract)
        let compose = container.makeReceiptComposeViewModel(user: fa, editing: contract)
        XCTAssertEqual(compose.screenTitle, "수금 수정")
        XCTAssertEqual(compose.draft.client, "CAMPUS")
        XCTAssertEqual(compose.draft.status, .pending)
        XCTAssertFalse(compose.canSubmit, "바뀐 게 없으면 보낼 수 없어요")

        compose.draft.status = .collected
        await compose.submit()
        XCTAssertTrue(compose.didSave)

        let reloaded = container.makeContractDetailViewModel(contractId: 7)
        await reloaded.load()
        let updated = try XCTUnwrap(reloaded.state.value?.contract)
        XCTAssertEqual(updated.status, .collected)
        XCTAssertEqual(updated.amount, contract.amount, "금액은 그대로")
        XCTAssertEqual(updated.title, contract.title)
    }

    func testChangesOnlyIncludeEditedValues() throws {
        var original = ReceiptDraft()
        original.client = "A"
        original.project = "P"
        original.amountText = "100"
        original.status = .billed
        let body = ServerReceiptWriteRequestDTO(amount: 200)
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(body), encoding: .utf8))
        XCTAssertEqual(json, #"{"amount":200}"#, "비운 값은 보내지 않아요")

        var draft = original
        draft.amountText = "200"
        XCTAssertEqual(draft.amount, 200)
        XCTAssertEqual(ReceiptDraft(FinanceContract(id: 1, name: "A", title: "P", amount: 100, collectedAt: Date(), status: .collected)).status, .collected)
    }

    func testValidation() async throws {
        let compose = makeContainer().makeReceiptComposeViewModel(user: fa)
        compose.draft.client = "A"
        compose.draft.project = "  "
        compose.draft.amountText = "1000"
        XCTAssertFalse(compose.canSubmit)
        compose.draft.project = "P"
        compose.draft.amountText = "0"
        XCTAssertFalse(compose.canSubmit, "금액은 1원 이상")
        compose.draft.amountText = "abc"
        XCTAssertNil(compose.draft.amount)
        XCTAssertFalse(compose.canSubmit)
    }

    func testOnlyFAOrAdminCanSave() async throws {
        XCTAssertTrue(fa.can(.manageReceipts))
        XCTAssertTrue(AuthUser(id: 3, name: "관리자", roles: [.admin]).can(.manageReceipts))
        XCTAssertFalse(leader.can(.manageReceipts), "운영진도 등록은 못 해요 (서버 Admin · FA)")

        let compose = makeContainer().makeReceiptComposeViewModel(user: leader)
        compose.draft.client = "A"
        compose.draft.project = "P"
        compose.draft.amountText = "1000"
        await compose.submit()
        XCTAssertFalse(compose.didSave)
        XCTAssertEqual(compose.errorMessage, "수금 내역은 FA · 관리자만 등록할 수 있어요.")
    }
}
