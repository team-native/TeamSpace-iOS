import Foundation

/// 보안 토큰 저장소 (구현: Keychain)
protocol TokenStorage: Sendable {
    /// - Parameter persistent: true 면 앱을 다시 켜도 유지(로그인 상태 유지), false 면 이번 실행 동안만 보관
    func save(_ token: AuthToken, persistent: Bool) throws
    func load() -> AuthToken?
    func clear() throws
}
