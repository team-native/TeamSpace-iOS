import Foundation

/// Preview · 테스트용 토큰 저장소
final class InMemoryTokenStorage: TokenStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var token: AuthToken?
    private(set) var lastSavedAsPersistent: Bool?

    func save(_ token: AuthToken, persistent: Bool) throws {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
        lastSavedAsPersistent = persistent
    }

    func load() -> AuthToken? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        token = nil
    }
}
