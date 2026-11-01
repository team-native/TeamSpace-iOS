import Foundation

/// 기기 알림 권한 (UNUserNotificationCenter) 을 감싼 저장소
protocol NotificationPermissionRepository: Sendable {
    func currentStatus() async -> NotificationPermissionStatus
    /// 시스템 권한 팝업을 띄웁니다. 이미 결정된 경우 팝업 없이 현재 값을 돌려줘요.
    func requestAuthorization() async throws -> NotificationPermissionStatus
}
