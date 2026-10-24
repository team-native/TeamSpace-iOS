import Foundation

struct RequestPasswordResetUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute(email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2, parts[1].contains(".") else {
            throw AppError.invalidInput("가입한 이메일을 정확히 입력해 주세요.")
        }
        try await authRepository.requestPasswordReset(email: trimmed)
    }
}
