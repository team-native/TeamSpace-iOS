import Foundation

struct RequestAccountUseCase {
    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute(_ form: AccountRequestForm) async throws -> AccountRequestReceipt {
        guard form.isSubmittable else {
            throw AppError.invalidInput("입력한 정보를 다시 확인해 주세요.")
        }
        var trimmed = form
        trimmed.name = form.trimmedName
        trimmed.email = form.email.trimmingCharacters(in: .whitespaces)
        return try await authRepository.requestAccount(trimmed)
    }
}
