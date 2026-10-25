import UIKit
import UserNotifications

/// 푸시 알림(APNs) 콜백을 받기 위한 AppDelegate. `TeamSpaceApp` 에서 어댑터로 연결합니다.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let pushTokenRegistrar = PushTokenRegistrar()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { await registerIfAlreadyAuthorized(application) }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        pushTokenRegistrar.receive(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 시뮬레이터 · Push 권한(entitlement) 미설정 시 여기로 옵니다.
        AppLog.record(error, context: "registerForRemoteNotifications", logger: AppLog.push)
    }

    /// 앱을 보고 있을 때도 배너로 보여줍니다.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// 이미 권한이 있으면 실행할 때마다 토큰을 새로 받습니다. (토큰은 바뀔 수 있음)
    private func registerIfAlreadyAuthorized(_ application: UIApplication) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if SystemNotificationPermissionRepository.map(settings.authorizationStatus) == .authorized {
            application.registerForRemoteNotifications()
        }
    }
}
