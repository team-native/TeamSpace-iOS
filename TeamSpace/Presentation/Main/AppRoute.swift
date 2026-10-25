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
    case financeMonthlyFlow(month: Date) // 04-5 월별 흐름
    case financeComposition(month: Date) // 04-6 돈의 구성
    case financeAccess              // 04-7 재정 제한 권한
    case financeProjectAmounts      // 04-9 프로젝트별 금액 (권한 없으면 04-8)
    // 05 결재
    case approvalDetail(documentId: Int) // 05-3 내 결재 상세 · 05-4 받은 결재 검토
    case approvalCompose                 // 05-0 결재 올리기 · 종류 선택
    // 06 문서함
    case librarySearch                   // 06-2 문서 검색
    // 아직 만들지 않은 화면
    case comingSoon(title: String)
}
