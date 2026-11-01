import Foundation

/// 앱 시작 시 자동 로그인 — 저장된 토큰이 있으면 내 정보를 불러옵니다.
struct RestoreSessionUseCase {
    private let authRepository: AuthRepository
    private let tokenStorage: TokenStorage

    init(authRepository: AuthRepository, tokenStorage: TokenStorage) {
        self.authRepository = authRepository
        self.tokenStorage = tokenStorage
    }

    /// 토큰이 없거나 만료(401)면 nil — 로그인 화면으로 보냅니다.
    /// 네트워크 오류 등 일시적인 문제는 토큰을 지우지 않고 에러를 던집니다.
    func execute() async throws -> AuthUser? {
        guard tokenStorage.load() != nil else { return nil }
        do {
            return try await authRepository.fetchMe()
        } catch AppError.unauthorized {
            try tokenStorage.clear()
            return nil
        }
    }
}
