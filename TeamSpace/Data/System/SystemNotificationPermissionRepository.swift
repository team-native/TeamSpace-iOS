import UIKit
import UserNotifications

/// iOS 알림 권한 — UNUserNotificationCenter 를 감쌉니다.
/// 권한이 허용되면 APNs 등록까지 요청하고, 토큰은 AppDelegate 가 받아 서버로 보냅니다.
final class SystemNotificationPermissionRepository: NotificationPermissionRepository, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func currentStatus() async -> NotificationPermissionStatus {
        let settings = await center.notificationSettings()
        return Self.map(settings.authorizationStatus)
    }

    func requestAuthorization() async throws -> NotificationPermissionStatus {
        let status = await currentStatus()
        guard status == .notDetermined else {
            if status == .authorized { await registerForRemoteNotifications() }
            return status
        }
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted { await registerForRemoteNotifications() }
        return granted ? .authorized : .denied
    }

    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    static func map(_ status: UNAuthorizationStatus) -> NotificationPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        @unknown default: return .denied
        }
    }
}
