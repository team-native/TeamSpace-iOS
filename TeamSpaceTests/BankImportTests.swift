import XCTest
@testable import TeamSpace

/// 은행 거래 확인 · 반영 (/finance/bank-imports · /finance/bank-import-commits)
@MainActor
final class BankImportTests: XCTestCase {
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa, .pm])
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testListGroupsByStatus() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()
        XCTAssertEqual(viewModel.filter, .open)
        XCTAssertEqual(viewModel.items.map(\.id), ["105", "104", "103"], "최근 거래가 먼저")
        XCTAssertEqual(viewModel.count(.confirmed), 0)
        XCTAssertEqual(viewModel.count(.done), 2)
        XCTAssertFalse(viewModel.canCommit)

        let inbound = try XCTUnwrap(viewModel.items.first)
        XCTAssertEqual(inbound.direction, .inbound)
        XCTAssertEqual(inbound.amountText, "+3,000,000원")
        XCTAssertEqual(inbound.matchText, "연결: Green Note · (주)그린랩")
        XCTAssertTrue(inbound.canConfirm)
        let unmatched = try XCTUnwrap(viewModel.items.last)
        XCTAssertFalse(unmatched.canConfirm, "연결 계약이 없는 입금은 확인할 수 없어요")
        XCTAssertEqual(unmatched.matchText, "연결된 수주 계약 없음")

        viewModel.filter = .done
        let committed = try XCTUnwrap(viewModel.items.first { $0.status == .committed })
        XCTAssertEqual(committed.committedBy, "양지우")
        XCTAssertNotNil(committed.committedAt)
    }

    func testConfirmExcludeAndCommit() async throws {
        let container = makeContainer()
        let viewModel = container.makeBankImportViewModel(user: admin)
        await viewModel.load()
        let items = viewModel.items
        await viewModel.review(items[0], .confirm)
        await viewModel.review(items[1], .confirm)
        await viewModel.review(items[2], .exclude)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.count(.open), 0)
        XCTAssertEqual(viewModel.count(.confirmed), 2)
        XCTAssertEqual(viewModel.confirmedTotalText, "입금 3,000,000원 · 출금 54,000원")
        XCTAssertEqual(viewModel.commitTitle, "확인한 2건 재정에 반영")

        await viewModel.commit()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.toastMessage, "2건을 재정에 반영했어요 (수금 1 · 지출 1)")
        XCTAssertEqual(viewModel.count(.confirmed), 0)
        XCTAssertEqual(viewModel.count(.done), 5)
        XCTAssertFalse(viewModel.canCommit)
    }

    func testUnconfirmMovesBack() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()
        let outbound = try XCTUnwrap(viewModel.items.first { $0.id == "104" })
        await viewModel.review(outbound, .confirm)
        XCTAssertEqual(viewModel.count(.confirmed), 1)
        viewModel.filter = .confirmed
        await viewModel.review(try XCTUnwrap(viewModel.items.first), .unconfirm)
        XCTAssertEqual(viewModel.count(.confirmed), 0)
        viewModel.filter = .open
        XCTAssertEqual(viewModel.items.first { $0.id == "104" }?.status, .needsReview)
    }

    func testRulesAndErrors() async throws {
        let viewModel = makeContainer().makeBankImportViewModel(user: fa)
        await viewModel.load()
        let unmatched = try XCTUnwrap(viewModel.items.first { $0.id == "103" })
        await viewModel.review(unmatched, .confirm)
        XCTAssertEqual(viewModel.errorMessage, "연결된 수주 계약이 없는 입금이에요. 계약을 연결하거나 제외해 주세요.")

        viewModel.errorMessage = nil
        viewModel.filter = .done
        let committed = try XCTUnwrap(viewModel.items.first { $0.status == .committed })
        await viewModel.review(committed, .exclude)
        XCTAssertEqual(viewModel.errorMessage, "이미 재정에 반영된 거래예요.")

        let repository = BankImportRepositoryImpl(client: APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: InMemoryTokenStorage()
        ))
        do {
            _ = try await CommitBankImportsUseCase(bankImportRepository: repository).execute(viewModel.items, user: fa)
            XCTFail("확인 완료 거래가 없으면 못 보내요")
        } catch {
            XCTAssertEqual(error.userMessage, "반영할 확인 완료 거래가 없어요.")
        }
        do {
            _ = try await repository.commit(rowIds: ["104"])
            XCTFail("확인 안 한 거래는 서버가 막아요")
        } catch {
            XCTAssertEqual(error.userMessage, "선택한 거래 중 확인되지 않았거나 이미 반영된 항목이 있습니다.")
        }
    }

    func testOnlyFinanceAdminsCanManage() async {
        XCTAssertTrue(fa.can(.manageBankImports))
        XCTAssertTrue(admin.can(.manageBankImports))
        XCTAssertFalse(leader.can(.manageBankImports), "Leader 는 볼 수만 있어요 (서버 FA · Admin)")
        let viewModel = makeContainer().makeBankImportViewModel(user: leader)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("FA · Admin 만 볼 수 있어요") }
    }
}
