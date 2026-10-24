import XCTest
@testable import TeamSpace

@MainActor
final class LoginViewModelTests: XCTestCase {
    /// XCTest 는 테스트 메서드마다 새 인스턴스를 만들어서 저장소도 매번 새로 생겨요.
    private let tokenStorage = InMemoryTokenStorage()

    private func makeViewModel() -> LoginViewModel {
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let useCase = LoginUseCase(authRepository: AuthRepositoryImpl(client: client), tokenStorage: tokenStorage)
        return LoginViewModel(loginUseCase: useCase)
    }

    func testButtonDisabledUntilEmailAndPasswordAreValid() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.email = "s26043"
        viewModel.password = "1234"
        XCTAssertFalse(viewModel.canSubmit, "이메일 형식이 아니면 비활성화")

        viewModel.email = "s26043@gsm.hs.kr"
        XCTAssertTrue(viewModel.canSubmit)

        viewModel.password = ""
        XCTAssertFalse(viewModel.canSubmit, "비밀번호가 비면 비활성화")
    }

    func testLoginSuccessReturnsUserAndSavesToken() async {
        let viewModel = makeViewModel()
        viewModel.email = "s26043@gsm.hs.kr"
        viewModel.password = "abcd1234"
        viewModel.keepSignedIn = false

        let user = await viewModel.login()

        XCTAssertEqual(user?.name, "홍길동")
        XCTAssertEqual(user?.roles, [.member])
        XCTAssertEqual(tokenStorage.load()?.accessToken, "mock-access-token")
        XCTAssertEqual(tokenStorage.lastSavedAsPersistent, false, "로그인 상태 유지를 끄면 영구 저장하지 않아요")
    }

    func testWrongPasswordShowsCredentialError() async {
        let viewModel = makeViewModel()
        viewModel.email = "s26043@gsm.hs.kr"
        viewModel.password = MockTransport.failingPassword

        let user = await viewModel.login()

        XCTAssertNil(user)
        XCTAssertEqual(viewModel.errorMessage, AppError.invalidCredentials.userMessage)
        XCTAssertTrue(viewModel.hasFieldError)
        XCTAssertNil(tokenStorage.load())

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }
}
