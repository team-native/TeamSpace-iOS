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
            return !roles.isDisjoint(with: [.leader, .admin])
        case .publishNotice:
            return !roles.isDisjoint(with: [.fa, .leader, .admin])
        }
    }

    /// 04-1 "내 권한: 구성원"
    var financeScopeTitle: String {
        if can(.viewFinanceDetail) { return roles.contains(.fa) ? "FA" : "운영진" }
        return "구성원"
    }
}
