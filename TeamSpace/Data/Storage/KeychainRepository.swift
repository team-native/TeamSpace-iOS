import Foundation
import Security

/// 보안 토큰은 UserDefaults 가 아닌 Keychain 에 저장합니다.
/// '로그인 상태 유지'를 끄면 Keychain 에 남기지 않고 이번 실행 동안 메모리에만 둡니다.
final class KeychainRepository: TokenStorage, @unchecked Sendable {
    private let service: String
    private let account = "auth-token"
    private let lock = NSLock()
    private var sessionToken: AuthToken?

    init(service: String = "com.native.teamspace") {
        self.service = service
    }

    func save(_ token: AuthToken, persistent: Bool) throws {
        try clear()
        guard persistent else {
            setSessionToken(token)
            return
        }
        let data = try JSONEncoder().encode(StoredToken(accessToken: token.accessToken, refreshToken: token.refreshToken))
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.unknown("keychain save status=\(status)")
        }
    }

    func load() -> AuthToken? {
        if let token = currentSessionToken() { return token }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard
            status == errSecSuccess,
            let data = item as? Data,
            let stored = try? JSONDecoder().decode(StoredToken.self, from: data)
        else {
            return nil
        }
        return AuthToken(accessToken: stored.accessToken, refreshToken: stored.refreshToken)
    }

    func clear() throws {
        setSessionToken(nil)
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.unknown("keychain delete status=\(status)")
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func setSessionToken(_ token: AuthToken?) {
        lock.lock()
        defer { lock.unlock() }
        sessionToken = token
    }

    private func currentSessionToken() -> AuthToken? {
        lock.lock()
        defer { lock.unlock() }
        return sessionToken
    }

    private struct StoredToken: Codable {
        let accessToken: String
        let refreshToken: String
    }
}
