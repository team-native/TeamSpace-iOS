import Foundation

/// 알림 설정 저장소 — 서버 GET · PATCH /me/notification-settings, 기기 저장소는 캐시로 써요.
protocol NotificationSettingsRepository: Sendable {
    func fetch() async -> NotificationSettings
    func save(_ settings: NotificationSettings) async throws
}
