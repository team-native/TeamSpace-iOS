import SwiftUI

/// AppRoute → 실제 화면. ViewModel 은 DIContainer 가 만들어 줍니다.
struct AppRouteView: View {
    let route: AppRoute
    let container: DIContainer
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        switch route {
        case .notificationCenter:
            NotificationCenterView(viewModel: container.makeNotificationCenterViewModel(), onNavigate: onNavigate)
        case .notificationSettings:
            NotificationSettingsView(viewModel: container.makeNotificationSettingsViewModel(), onNavigate: onNavigate)
        case .notificationPermission:
            NotificationPermissionView(viewModel: container.makeNotificationPermissionViewModel(), onNavigate: onNavigate)
        case .notificationTroubleshoot:
            NotificationTroubleshootView(
                viewModel: container.makeNotificationTroubleshootViewModel(),
                onNavigate: onNavigate
            )
        case .comingSoon(let title):
            ComingSoonView(title: title, showsBackButton: true)
        }
    }
}
