import Foundation

struct RegisterPushTokenUseCase {
    private let pushTokenRepository: PushTokenRepository

    init(pushTokenRepository: PushTokenRepository) {
        self.pushTokenRepository = pushTokenRepository
    }

    /// 빈 토큰은 서버로 보내지 않습니다.
    func execute(token: String) async throws {
        guard !token.isEmpty else { throw AppError.invalidInput("푸시 토큰이 비어 있어요.") }
        try await pushTokenRepository.register(token: token)
    }
}
