import Foundation

protocol AuthRepository: Sendable {
    /// POST /auth/login
    func login(_ credential: LoginCredential) async throws -> AuthSession
}
