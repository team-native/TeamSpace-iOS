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

    func fetchMe() async throws -> AuthUser {
        do {
            return try await client.request(Endpoint(method: .get, path: "users/me"), as: UserMeResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    // TODO: API 명세서에 계정 요청 API 추가되면 경로 · 필드명 확인
    func requestAccount(_ form: AccountRequestForm) async throws -> AccountRequestReceipt {
        guard let department = form.department else {
            throw AppError.invalidInput("소속 부서를 선택해 주세요.")
        }
        let endpoint = Endpoint(
            method: .post,
            path: "auth/account-requests",
            body: AccountRequestRequestDTO(
                name: form.name,
                email: form.email,
                department: department.rawValue,
                password: form.password
            ),
            requiresAuth: false
        )
        do {
            return try await client.request(endpoint, as: AccountRequestResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    // TODO: API 명세서에 비밀번호 재설정 API 추가되면 경로 확인
    func requestPasswordReset(email: String) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "auth/password-reset",
            body: PasswordResetRequestDTO(email: email),
            requiresAuth: false
        )
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            // data 없이 성공 응답만 오는 경우도 성공으로 봅니다.
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
