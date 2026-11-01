import SwiftUI

extension FinancePoolKind {
    var title: String {
        switch self {
        case .operation: return "운영풀"
        case .reserve: return "적립풀"
        case .dividend: return "배당풀"
        case .unknown: return "기타"
        }
    }

    var tint: Color {
        switch self {
        case .operation: return .tsPrimary
        case .reserve: return .tsViolet
        case .dividend: return .tsApricot
        case .unknown: return .tsInk2
        }
    }

    var background: Color {
        switch self {
        case .operation: return .tsPrimarySoft
        case .reserve: return .tsVioletSoft
        case .dividend: return .tsApricotSoft
        case .unknown: return .tsSurface2
        }
    }
}

extension ContractStatus {
    var title: String {
        switch self {
        case .negotiating: return "협의 중"
        case .contracted: return "계약 완료"
        case .completed: return "납품 완료"
        case .unknown: return "확인 필요"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .negotiating: return .amber
        case .contracted: return .primary
        case .completed: return .positive
        case .unknown: return .neutral
        }
    }
}

extension NoticeCategory {
    var title: String {
        switch self {
        case .finance: return "재무"
        case .rule: return "규칙"
        case .notice: return "공지"
        case .unknown: return "기타"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .finance: return .primary
        case .rule: return .neutral
        case .notice: return .warning
        case .unknown: return .neutral
        }
    }
}

/// 홈 재무 카드의 금액 기준
enum HomeFinanceMode: Hashable, CaseIterable {
    case available
    case holding

    var title: String {
        switch self {
        case .available: return "사용 가능"
        case .holding: return "Native 보유금"
        }
    }

    var caption: String {
        switch self {
        case .available: return "지금 사용할 수 있는 금액"
        case .holding: return "Native 가 보유한 전체 금액"
        }
    }
}

/// 홈 "필요한 일에 바로" 바로가기
enum HomeShortcut: CaseIterable, Identifiable {
    case submitApproval
    case findDocument
    case teamBoard
    case inquiry
    case members

    var id: Self { self }

    var title: String {
        switch self {
        case .submitApproval: return "결재 올리기"
        case .findDocument: return "문서 찾기"
        case .teamBoard: return "팀 게시판"
        case .inquiry: return "문의 · 건의"
        case .members: return "팀원 소개"
        }
    }
}
