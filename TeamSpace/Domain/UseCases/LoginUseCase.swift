import Foundation

struct LoginUseCase {
    private let authRepository: AuthRepository
    private let tokenStorage: TokenStorage

    init(authRepository: AuthRepository, tokenStorage: TokenStorage) {
        self.authRepository = authRepository
        self.tokenStorage = tokenStorage
    }

    /// 로그인 후 토큰을 저장하고 사용자 정보를 돌려줍니다.
    func execute(_ credential: LoginCredential) async throws -> AuthUser {
        let email = credential.email.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty, !credential.password.isEmpty else {
            throw AppError.invalidInput("이메일과 비밀번호를 입력해 주세요.")
        }
        let trimmed = LoginCredential(email: email, password: credential.password, keepSignedIn: credential.keepSignedIn)
        let session = try await authRepository.login(trimmed)
        try tokenStorage.save(session.token, persistent: credential.keepSignedIn)
        return session.user
    }
}
