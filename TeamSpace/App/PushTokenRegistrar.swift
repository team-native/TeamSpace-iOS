import Foundation

/// APNs 토큰을 받아 두었다가, 로그인된 상태일 때 서버에 등록합니다.
/// (토큰은 앱 시작 직후, 로그인은 그 뒤에 일어날 수 있어서 둘 다 갖춰질 때 보냅니다.)
@MainActor
final class PushTokenRegistrar {
    private var registerPushTokenUseCase: RegisterPushTokenUseCase?
    private var token: String?
    private var isSignedIn = false
    private var registeredToken: String?

    func configure(registerPushTokenUseCase: RegisterPushTokenUseCase) {
        self.registerPushTokenUseCase = registerPushTokenUseCase
        registerIfPossible()
    }

    func receive(deviceToken: Data) {
        // TODO: FCM 을 쓰기로 하면 Firebase Messaging 토큰으로 바꿔 보냅니다.
        token = deviceToken.map { String(format: "%02x", $0) }.joined()
        registerIfPossible()
    }

    func setSignedIn(_ signedIn: Bool) {
        isSignedIn = signedIn
        if !signedIn { registeredToken = nil }
        registerIfPossible()
    }

    private func registerIfPossible() {
        guard
            isSignedIn,
            let token,
            token != registeredToken,
            let registerPushTokenUseCase
        else { return }
        registeredToken = token
        Task {
            do {
                try await registerPushTokenUseCase.execute(token: token)
                AppLog.push.info("push token registered")
            } catch {
                registeredToken = nil
                AppLog.record(error, context: "registerPushToken", logger: AppLog.push)
            }
        }
    }
}
