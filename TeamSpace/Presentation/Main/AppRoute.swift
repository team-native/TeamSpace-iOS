import Foundation

/// 탭 안 NavigationStack 에서 이동하는 화면 경로.
/// 새 화면을 만들면 여기에 case 를 추가하고 `AppRouteView` 에 연결하세요.
enum AppRoute: Hashable {
    case comingSoon(title: String)
}
