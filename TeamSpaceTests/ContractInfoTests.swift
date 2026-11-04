import XCTest
@testable import TeamSpace

/// 계약 정보 등록 · 수정 [FA · Admin] (POST /admin/finance/contracts · PATCH /admin/finance/contracts/{project})
@MainActor
final class ContractInfoTests: XCTestCase {
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa, .pm])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func detail(_ container: DIContainer, id: Int) async throws -> ContractDetail {
        let viewModel = container.makeContractDetailViewModel(contractId: id)
        await viewModel.load()
        return try XCTUnwrap(viewModel.state.value)
    }

    func testRegisterContractForReceiptWithoutOne() async throws {
        let container = makeContainer()
        // 2 = MOTION 브랜드 웹 구축 (계약 정보 없음)
        let before = try await detail(container, id: 2)
        XCTAssertNil(before.info)
        let compose = container.makeContractInfoComposeViewModel(user: fa, detail: before)
        XCTAssertEqual(compose.screenTitle, "계약 정보 등록")
        XCTAssertEqual(compose.project, "브랜드 웹 구축")
        XCTAssertEqual(compose.draft.total, before.contract.amount, "수금 금액으로 채워요")

        compose.draft.pm = "안율 · PM"
        compose.draft.step = 4
        compose.draft.staff = "Web 2 · Design 1"
        compose.draft.next = "11.20 잔금 예정"
        XCTAssertEqual(compose.draft.stepText, "제작까지 끝났어요")
        await compose.submit()
        XCTAssertTrue(compose.didSave)
        XCTAssertNil(compose.errorMessage)

        let after = try await detail(container, id: 2)
        XCTAssertEqual(after.info?.pm, "안율 · PM")
        XCTAssertEqual(after.managerName, "안율")
        XCTAssertEqual(after.memberCount, 3)
        XCTAssertEqual(after.steps.filter(\.isDone).count, 4)
        XCTAssertEqual(after.pools.map(\.ratio), [60, 30, 10])
    }

    func testEditSendsOnlyChangedFields() async throws {
        let container = makeContainer()
        // 1 = BRIDGE iOS 앱 프로토타입 (예시 계약 있음)
        let before = try await detail(container, id: 1)
        let info = try XCTUnwrap(before.info)
        let compose = container.makeContractInfoComposeViewModel(user: fa, detail: before)
        XCTAssertEqual(compose.screenTitle, "계약 정보 수정")
        XCTAssertEqual(compose.draft.pm, info.pm)
        XCTAssertFalse(compose.canSubmit, "바뀐 게 없으면 보낼 수 없어요")

        compose.draft.staff = "iOS 3 · Design 1 · Backend 1 · PM 1"
        await compose.submit()
        XCTAssertTrue(compose.didSave)

        let after = try await detail(container, id: 1)
        XCTAssertEqual(after.memberCount, 6)
        XCTAssertEqual(after.info?.signed, info.signed, "다른 값은 그대로")
        XCTAssertEqual(after.documentName, before.documentName, "보내지 않은 파일 이름도 그대로")
    }

    func testValidation() async throws {
        let container = makeContainer()
        let compose = container.makeContractInfoComposeViewModel(user: fa, detail: try await detail(container, id: 2))
        compose.draft.split = "운영 60% · 적립 30%"
        XCTAssertEqual(compose.splitText, "합계 90% — 100%가 되게 해 주세요")
        await compose.submit()
        XCTAssertEqual(compose.errorMessage, "풀 배분 비율의 합이 100%가 되게 해 주세요. (지금 90%)")

        compose.errorMessage = nil
        compose.draft.split = "운영 60% · 적립 30% · 배당 10%"
        compose.draft.collectedText = String((compose.draft.total ?? 0) + 1)
        await compose.submit()
        XCTAssertEqual(compose.errorMessage, "받은 금액이 계약 금액보다 커요.")
        XCTAssertFalse(compose.didSave)

        compose.draft.totalText = ""
        XCTAssertFalse(compose.canSubmit)
    }

    func testRequestBodyOmitsEmptyValues() throws {
        let body = ServerContractWriteRequestDTO(staff: "iOS 1")
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(body), encoding: .utf8))
        XCTAssertEqual(json, #"{"staff":"iOS 1"}"#)

        var draft = ContractInfoDraft(ContractInfo(pm: nil, signed: "2026.09.02", total: 10, collected: nil, step: 6, staff: nil, split: nil, next: nil))
        XCTAssertEqual(draft.signedText(), "2026.09.02")
        XCTAssertEqual(draft.stepText, "수금까지 끝났어요")
        draft.step = 0
        XCTAssertEqual(draft.stepText, "아직 시작 전이에요")
    }

    func testOnlyFAOrAdminCanSave() async throws {
        let container = makeContainer()
        let compose = container.makeContractInfoComposeViewModel(user: leader, detail: try await detail(container, id: 2))
        await compose.submit()
        XCTAssertFalse(compose.didSave)
        XCTAssertEqual(compose.errorMessage, "계약 정보는 FA · 관리자만 고칠 수 있어요.")
    }
}
