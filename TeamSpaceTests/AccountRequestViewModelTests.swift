import XCTest
@testable import TeamSpace

@MainActor
final class AccountRequestViewModelTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func filledViewModel() -> AccountRequestViewModel {
        let viewModel = makeContainer().makeAccountRequestViewModel()
        viewModel.form.name = "옥물결"
        viewModel.form.email = "s26043@gsm.hs.kr"
        viewModel.select(.design)
        viewModel.form.password = "abcd1234"
        return viewModel
    }

    func testSubmitEnabledOnlyWhenAllFieldsValid() {
        let viewModel = filledViewModel()
        XCTAssertTrue(viewModel.canSubmit)

        viewModel.form.password = "abcdefgh"
        XCTAssertFalse(viewModel.canSubmit, "숫자가 없으면 비밀번호 규칙 불충족")
        XCTAssertEqual(viewModel.passwordRuleState, .invalid)

        viewModel.form.password = "abcd1234"
        viewModel.form.department = nil
        XCTAssertFalse(viewModel.canSubmit, "부서를 고르지 않으면 비활성화")
    }

    func testSubmitReturnsReceipt() async {
        let viewModel = filledViewModel()

        let receipt = await viewModel.submit()

        XCTAssertEqual(receipt?.name, "옥물결")
        XCTAssertEqual(receipt?.department, .design)
        XCTAssertEqual(receipt?.status, .reviewing)
    }

    func testDuplicateEmailShowsConflictMessage() async {
        let viewModel = filledViewModel()
        viewModel.form.email = "taken@gsm.hs.kr"

        let receipt = await viewModel.submit()

        XCTAssertNil(receipt)
        XCTAssertEqual(viewModel.errorMessage, "이미 요청된 이메일입니다.")
    }

    func testPasswordResetValidatesEmail() async {
        let viewModel = makeContainer().makePasswordResetViewModel()

        viewModel.present(prefilledEmail: "wrong-format")
        await viewModel.send()
        XCTAssertEqual(viewModel.resultMessage, "가입한 이메일을 정확히 입력해 주세요.")

        viewModel.email = "s26043@gsm.hs.kr"
        await viewModel.send()
        XCTAssertEqual(viewModel.resultTitle, "메일을 보냈어요")
    }
}
