import Foundation
import Observation

/// 로그인 상태 — 앱 시작(자동 로그인 확인) / 로그아웃 / 로그인됨
@Observable
@MainActor
final class AppSession {
    enum State: Equatable {
        case launching
        case signedOut
        case signedIn(AuthUser)
    }

    private(set) var state: State = .launching
    /// 로그인이 만료돼 로그인 화면으로 돌아왔을 때 한 번 보여줄 안내
    var isExpiredNoticePresented = false

    private let restoreSessionUseCase: RestoreSessionUseCase
    private let logoutUseCase: LogoutUseCase

    init(restoreSessionUseCase: RestoreSessionUseCase, logoutUseCase: LogoutUseCase) {
        self.restoreSessionUseCase = restoreSessionUseCase
        self.logoutUseCase = logoutUseCase
    }

    var currentUser: AuthUser? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    /// 앱 시작 시 한 번 — 저장된 토큰으로 자동 로그인
    func restore() async {
        guard state == .launching else { return }
        do {
            if let user = try await restoreSessionUseCase.execute() {
                state = .signedIn(user)
            } else {
                state = .signedOut
            }
        } catch {
            // 네트워크 문제 등 — 토큰은 남겨 두고 일단 로그인 화면으로
            AppLog.record(error, context: "restoreSession", logger: AppLog.auth)
            state = .signedOut
        }
    }

    func signIn(_ user: AuthUser) {
        state = .signedIn(user)
    }

    /// 토큰 갱신까지 실패해 토큰이 지워졌을 때 — 다시 로그인하도록 안내해요.
    func expire() {
        guard case .signedIn = state else { return }
        isExpiredNoticePresented = true
        state = .signedOut
    }

    func signOut() {
        do {
            try logoutUseCase.execute()
        } catch {
            AppLog.record(error, context: "logout", logger: AppLog.auth)
        }
        state = .signedOut
    }
}
