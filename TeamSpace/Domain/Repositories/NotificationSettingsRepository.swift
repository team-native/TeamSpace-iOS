import Foundation

/// 알림 설정 저장소. 명세서에 설정 API 가 없어 지금은 기기에만 저장합니다.
protocol NotificationSettingsRepository: Sendable {
    func fetch() async -> NotificationSettings
    func save(_ settings: NotificationSettings) async throws
}
