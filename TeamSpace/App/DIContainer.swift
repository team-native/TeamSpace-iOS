import Foundation

/// 의존성 조립소. 싱글톤(shared) 없이 앱 시작 시 한 번 만들어 생성자로 주입합니다.
final class DIContainer {
    private let tokenStorage: TokenStorage
    private let authRepository: AuthRepository

    init(apiClient: APIClient, tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
        self.authRepository = AuthRepositoryImpl(client: apiClient)
    }

    /// xcconfig 의 USE_MOCK_API / API_BASE_URL 에 따라 실서버 또는 Mock 서버를 씁니다.
    static func make(configuration: AppConfiguration = .current) -> DIContainer {
        let tokenStorage = KeychainRepository()
        let apiClient: APIClient
        if !configuration.usesMockAPI, let baseURL = configuration.apiBaseURL {
            apiClient = APIClient(baseURL: baseURL, transport: URLSessionTransport(), tokenStorage: tokenStorage)
        } else {
            apiClient = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(), tokenStorage: tokenStorage)
        }
        return DIContainer(apiClient: apiClient, tokenStorage: tokenStorage)
    }

    /// Preview 전용 (Mock 서버 + 메모리 토큰)
    static func preview() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let apiClient = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 300_000_000),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: apiClient, tokenStorage: tokenStorage)
    }

    var loginUseCase: LoginUseCase {
        LoginUseCase(authRepository: authRepository, tokenStorage: tokenStorage)
    }

    var requestAccountUseCase: RequestAccountUseCase {
        RequestAccountUseCase(authRepository: authRepository)
    }

    var requestPasswordResetUseCase: RequestPasswordResetUseCase {
        RequestPasswordResetUseCase(authRepository: authRepository)
    }
}

@MainActor
extension DIContainer {
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: loginUseCase)
    }

    func makePasswordResetViewModel() -> PasswordResetViewModel {
        PasswordResetViewModel(requestPasswordResetUseCase: requestPasswordResetUseCase)
    }

    func makeAccountRequestViewModel() -> AccountRequestViewModel {
        AccountRequestViewModel(requestAccountUseCase: requestAccountUseCase)
    }
}
