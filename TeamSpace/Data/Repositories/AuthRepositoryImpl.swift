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

    /// `POST /auth/signup-requests` — 202 `{id, status}`, 이미 있는 이메일이면 409
    func requestAccount(_ form: AccountRequestForm) async throws -> AccountRequestReceipt {
        guard let department = form.department else {
            throw AppError.invalidInput("소속 부서를 선택해 주세요.")
        }
        let endpoint = Endpoint(
            method: .post,
            path: "auth/signup-requests",
            body: AccountRequestRequestDTO(
                email: form.email,
                name: form.name,
                dept: department.rawValue,
                password: form.password,
                major: form.major.nilIfEmpty,
                cohort: form.cohort.nilIfEmpty,
                message: form.message.nilIfEmpty
            ),
            requiresAuth: false
        )
        do {
            return try await client.request(endpoint, as: AccountRequestResponseDTO.self)
                .toEntity(form: form, department: department)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    /// `POST /auth/password-reset-requests` — 가입 여부와 상관없이 202 `{accepted: true}`
    func requestPasswordReset(email: String) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "auth/password-reset-requests",
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
