import Foundation

/// 기능별로 필요한 권한 (컨벤션 22: 권한은 이 enum 하나로 관리)
/// 최종 판단은 서버 응답(403)이 기준이고, 앱은 버튼 숨김 같은 UI 힌트로만 사용합니다.
enum Permission: Hashable, Sendable {
    /// 재무 요약 (수금액 · 풀 배분)
    case viewFinanceSummary
    /// 재무 상세 (수주 상세 · 프로젝트별 금액 · 거래 내역)
    case viewFinanceDetail
    case approveDocument
    case manageProject
    case answerInquiry
    /// 10-7 전체 공지 작성 (NativeOps · FA · Leader)
    case publishNotice
    /// 공지 확인 현황 · 미확인자 (서버 `require_admin` — Admin 만)
    case viewNoticeReceipts
    /// 일정 추가 (서버 `require_admin` — Admin 만)
    case manageEvents
    /// 게시글 신고 처리 (서버 `require_admin` — Admin 만)
    case handleReports
    /// 가입 요청 승인 (서버 `require_admin` — Admin 만)
    case approveSignups
    /// 재정 열람 권한 주기 · 회수 (서버 `require_admin` — Admin 만)
    case manageFinancePermissions
    /// 프로젝트 등록 · 기본 정보 수정 (서버 `require_admin` — Admin 만)
    case registerProjects
    /// 문서함 · 규칙 문서 등록 · 개정 (서버 `require_admin` — Admin 만)
    case manageDocs
    /// 은행 거래 확인 · 재정 반영 (서버 `_require_finance_admin` — Admin · FA)
    case manageBankImports
    /// 수금 등록 · 수정 (서버 `/admin/finance/receipts` — Admin · FA)
    case manageReceipts
}

extension AuthUser {
    func can(_ permission: Permission) -> Bool {
        let roles = Set(roles)
        switch permission {
        case .viewFinanceSummary:
            return true
        case .viewFinanceDetail:
            return !roles.isDisjoint(with: [.fa, .leader, .admin])
        case .approveDocument:
            return !roles.isDisjoint(with: [.pm, .fa, .leader, .admin])
        case .manageProject:
            return !roles.isDisjoint(with: [.pm, .leader, .admin])
        case .answerInquiry:
            return !roles.isDisjoint(with: [.fa, .leader, .admin])
        case .publishNotice:
            return !roles.isDisjoint(with: [.fa, .leader, .admin])
        case .manageBankImports, .manageReceipts:
            return !roles.isDisjoint(with: [.fa, .admin])
        case .viewNoticeReceipts, .manageEvents, .handleReports, .approveSignups, .manageFinancePermissions, .registerProjects, .manageDocs:
            return roles.contains(.admin)
        }
    }

    /// 04-1 "내 권한: 구성원"
    var financeScopeTitle: String {
        if can(.viewFinanceDetail) { return roles.contains(.fa) ? "FA" : "운영진" }
        return "구성원"
    }
}
