import Foundation

final class AuthRepositoryImpl: AuthRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(_ credential: LoginCredential) async throws -> AuthSession {
        let endpoint = Endpoint(
            method: .post,
            path: "auth/login",
            body: LoginRequestDTO(email: credential.email, password: credential.password),
            requiresAuth: false
        )
        do {
            return try await client.request(endpoint, as: LoginResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            let appError = error.asAppError
            // 로그인에서의 401 은 "토큰 만료"가 아니라 "계정 불일치" 입니다.
            if case .unauthorized = appError { throw AppError.invalidCredentials }
            throw appError
        }
    }
}
