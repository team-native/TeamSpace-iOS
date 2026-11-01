import Foundation
import Observation

/// 01-1 로그인 — 입력값 · 버튼 활성화 · 로딩/오류 상태를 관리합니다.
@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var keepSignedIn = true
    private(set) var loginState: ViewState<AuthUser> = .idle

    private let loginUseCase: LoginUseCase

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    var isLoading: Bool {
        loginState.isLoading
    }

    var errorMessage: String? {
        loginState.error?.userMessage
    }

    /// 입력값 문제(400 · 계정 불일치)일 때만 입력창을 빨갛게 표시합니다. 네트워크 오류는 제외.
    var hasFieldError: Bool {
        switch loginState.error as? AppError {
        case .invalidInput, .invalidCredentials: return true
        default: return false
        }
    }

    var isEmailFormatValid: Bool {
        let parts = email.trimmingCharacters(in: .whitespaces).split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }

    /// 이메일 형식이 맞고 비밀번호가 입력됐을 때만 로그인 버튼을 켭니다.
    var canSubmit: Bool {
        isEmailFormatValid && !password.isEmpty && !isLoading
    }

    /// 성공하면 로그인한 사용자를, 실패하면 nil 을 돌려줍니다. (오류는 loginState 로 화면에 표시)
    @discardableResult
    func login() async -> AuthUser? {
        guard canSubmit else { return nil }
        loginState = .loading
        do {
            let credential = LoginCredential(email: email, password: password, keepSignedIn: keepSignedIn)
            let user = try await loginUseCase.execute(credential)
            loginState = .loaded(user)
            return user
        } catch {
            AppLog.record(error, context: "login", logger: AppLog.auth)
            loginState = .failed(error)
            return nil
        }
    }

    /// 입력을 고치기 시작하면 이전 오류 메시지를 지웁니다.
    func clearError() {
        if loginState.error != nil {
            loginState = .idle
        }
    }
}
