import Foundation
import Observation

/// 01-4 비밀번호 찾기 (iOS Alert)
@Observable
@MainActor
final class PasswordResetViewModel {
    var email = ""
    var isInputPresented = false
    private(set) var state: ViewState<Void> = .idle

    private let requestPasswordResetUseCase: RequestPasswordResetUseCase

    init(requestPasswordResetUseCase: RequestPasswordResetUseCase) {
        self.requestPasswordResetUseCase = requestPasswordResetUseCase
    }

    var canSend: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 결과 알림 제목 · 문구 (성공 / 실패일 때만)
    var resultTitle: String {
        if case .loaded = state { return "메일을 보냈어요" }
        return "보내지 못했어요"
    }

    var resultMessage: String? {
        switch state {
        case .loaded:
            return "가입한 이메일로 재설정 링크를 보냈어요. 메일함을 확인해 주세요."
        case .failed(let error):
            return error.userMessage
        default:
            return nil
        }
    }

    /// 로그인 화면에 입력한 이메일을 미리 채워서 엽니다.
    func present(prefilledEmail: String) {
        email = prefilledEmail
        state = .idle
        isInputPresented = true
    }

    func send() async {
        state = .loading
        do {
            try await requestPasswordResetUseCase.execute(email: email)
            state = .loaded(())
        } catch {
            AppLog.record(error, context: "passwordReset", logger: AppLog.auth)
            state = .failed(error)
        }
    }

    func dismissResult() {
        state = .idle
    }
}
