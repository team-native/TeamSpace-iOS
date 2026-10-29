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
    case approvalResume(kind: ApprovalComposeKind, title: String) // 07-5 임시 저장 문서 이어서 작성
    // 06 문서함
    case librarySearch                   // 06-2 문서 검색
    case templateDetail(id: Int)          // 06-3 템플릿 상세
    case templateCompose(kind: TemplateFormKind, title: String)
    // 07 내 공간
    case workspaceDashboard              // 07-1 내 공간 대시보드
    case workspaceTodos                  // 07-2 나의 To-do
    case workspaceDocuments              // 07-4 내가 제출한 문서
    case workspaceDrafts                 // 07-5 임시 저장 문서
    case workspaceProjects               // 07-6 참여 프로젝트
    case workspaceSchedules              // 07-7 일정 (07-9 시트 포함)
    case workspaceScheduleDetail(id: Int) // 07-8 전체 일정 상세
    case workspaceMyPosts                // 07-10 내가 쓴 게시글 · 댓글
    case workspaceMyProposals            // 07-11 내가 작성한 운영 제안
    case workspaceActivity               // 07-12 내 활동
    case workspaceProfile                // 07-13 프로필 편집 (07-16 미모티콘 바꾸기)
    case workspaceSettings               // 07-14 설정 (07-17 로그아웃 확인)
    case workspacePermissions            // 07-15 내 권한 · 접근 범위
    // 08 프로젝트
    case projects                        // 08-1 전체 프로젝트 탐색
    case projectDetail(id: Int)          // 08-2 프로젝트 상세
    case projectTimeline(id: Int)        // 08-8 프로젝트 일정과 변경 이력
    case projectRecruitment(id: Int)     // 08-3 모집 공고 (08-4 신청 시트 · 08-5 완료)
    case myApplications                  // 08-6 내 참여 신청 현황
    case applicantReview(projectId: Int) // 08-7 PM 지원자 검토
    // 09 규칙
    case rules                           // 09-1 규칙 · 제도
    case ruleDetail(id: Int)             // 09-2 문서 상세 · 규칙 (09-3 변경 내역 시트)
    case ruleComparison(id: Int)         // 09-4 규칙 개정 비교
    // 10 게시판 · 공지
    case board                           // 10-1 팀 게시판
    case boardSearch                     // 10-12 게시글 검색
    case postDetail(id: Int)             // 10-3 게시글 상세 (10-8 더보기 · 10-10 신고)
    case postCompose                     // 10-2 게시글 작성 (10-9 게시 완료)
    case commentCompose(postId: Int)     // 10-4 댓글 작성
    // 아직 만들지 않은 화면
    case comingSoon(title: String)
}
