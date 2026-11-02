import XCTest
@testable import TeamSpace

/// 07-14 설정 · 비밀번호 변경 — PATCH /me/settings
@MainActor
final class PasswordChangeTests: XCTestCase {
    private func makeViewModel() -> PasswordChangeViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makePasswordChangeViewModel()
    }

    func testValidation() {
        XCTAssertEqual(ChangePasswordUseCase.validationMessage(current: "", new: "newpass12", confirm: "newpass12"), "현재 비밀번호를 입력해 주세요.")
        XCTAssertEqual(ChangePasswordUseCase.validationMessage(current: "old", new: "short", confirm: "short"), "새 비밀번호는 8자 이상이어야 해요.")
        XCTAssertEqual(ChangePasswordUseCase.validationMessage(current: "samepass1", new: "samepass1", confirm: "samepass1"), "현재 비밀번호와 다른 비밀번호를 입력해 주세요.")
        XCTAssertEqual(ChangePasswordUseCase.validationMessage(current: "old", new: "newpass12", confirm: "newpass13"), "새 비밀번호가 서로 달라요.")
        XCTAssertNil(ChangePasswordUseCase.validationMessage(current: "old", new: "newpass12", confirm: "newpass12"))
    }

    func testChangeSucceedsAndClearsFields() async {
        let viewModel = makeViewModel()
        viewModel.currentPassword = "oldpass12"
        viewModel.newPassword = "newpass12"
        viewModel.confirmPassword = "newpass12"
        XCTAssertTrue(viewModel.canSubmit)

        await viewModel.submit()

        XCTAssertTrue(viewModel.didChange)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.currentPassword.isEmpty && viewModel.newPassword.isEmpty && viewModel.confirmPassword.isEmpty)
    }

    func testWrongCurrentPasswordShowsServerMessage() async {
        let viewModel = makeViewModel()
        viewModel.currentPassword = MockTransport.failingPassword
        viewModel.newPassword = "newpass12"
        viewModel.confirmPassword = "newpass12"

        await viewModel.submit()

        XCTAssertFalse(viewModel.didChange)
        XCTAssertEqual(viewModel.errorMessage, "현재 비밀번호가 일치하지 않습니다.")
    }

    func testMismatchIsCaughtBeforeServer() async {
        let viewModel = makeViewModel()
        viewModel.currentPassword = "oldpass12"
        viewModel.newPassword = "newpass12"
        viewModel.confirmPassword = "newpass1"
        XCTAssertEqual(viewModel.confirmHint, "새 비밀번호와 같게 입력해 주세요.")

        await viewModel.submit()

        XCTAssertFalse(viewModel.didChange)
        XCTAssertEqual(viewModel.errorMessage, "새 비밀번호가 서로 달라요.")
    }

    func testRequestBody() throws {
        let data = try JSONEncoder().encode(ServerPasswordChangeRequestDTO(currentPassword: "a", newPassword: "b"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(json, ["currentPassword": "a", "newPassword": "b"])
    }
}
