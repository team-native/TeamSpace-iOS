import SwiftUI

extension LibraryCategory: BadgeRepresentable {
    var badgeTitle: String {
        switch self {
        case .unknown: return "DOC"
        default: return rawValue
        }
    }

    var badgeTone: BadgeTone {
        switch self {
        case .rule: return .amber
        case .finance: return .primary
        case .template: return .violet
        case .guide: return .positive
        case .unknown: return .neutral
        }
    }
}

/// 06-1 상단 분류 카드 (전체 · 운영 규칙 · 재무 · 템플릿)
enum LibraryFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case rule
    case finance
    case template

    var id: String { rawValue }

    var category: LibraryCategory? {
        switch self {
        case .all: return nil
        case .rule: return .rule
        case .finance: return .finance
        case .template: return .template
        }
    }

    var title: String {
        switch self {
        case .all: return "전체"
        case .rule: return "운영 규칙"
        case .finance: return "재무"
        case .template: return "템플릿"
        }
    }

    var icon: TSIcon {
        switch self {
        case .all: return .file
        case .rule: return .bookOpen
        case .finance: return .wallet
        case .template: return .sparkles
        }
    }
}

extension LibraryRevision {
    /// "프로젝트 운영 원칙 · 10월 20일 시행"
    var bannerText: String {
        "\(title) · \(TSFormat.monthDay(effectiveAt)) 시행"
    }
}
