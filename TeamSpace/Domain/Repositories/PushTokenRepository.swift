import Foundation

/// 푸시 토큰 등록 (POST /notifications/push-token)
protocol PushTokenRepository: Sendable {
    func register(token: String) async throws
}
