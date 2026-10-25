import Foundation

/// 탭 안 NavigationStack 에서 이동하는 화면 경로.
/// 새 화면을 만들면 여기에 case 를 추가하고 `AppRouteView` 에 연결하세요.
enum AppRoute: Hashable {
    // 02 알림
    case notificationCenter
    case notificationSettings       // 02-9
    case notificationPermission     // 02-6
    case notificationTroubleshoot   // 02-7
    // 03 팀원
    case memberDirectory            // 목록 · 조직도
    case memberDetail(id: Int)
    // 04 재무
    case financeContractLedger      // 04-3 수금 내역
    case financeContractDetail(id: Int) // 04-2 수주 상세
    // 아직 만들지 않은 화면
    case comingSoon(title: String)
}
