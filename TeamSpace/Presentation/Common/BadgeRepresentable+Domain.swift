import Foundation

// Domain 상태 enum → StatusBadge 연결 (색상은 Presentation 에서만 결정)

extension AccountRequestStatus: BadgeRepresentable {
    var badgeTitle: String {
        switch self {
        case .reviewing: return "검토 중"
        case .approved: return "승인됨"
        case .rejected: return "반려됨"
        case .unknown: return "확인 중"
        }
    }

    var badgeTone: BadgeTone {
        switch self {
        case .reviewing: return .primary
        case .approved: return .positive
        case .rejected: return .negative
        case .unknown: return .neutral
        }
    }
}
