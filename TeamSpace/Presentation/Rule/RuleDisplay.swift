import SwiftUI

extension RuleCategory {
    var title: String {
        switch self {
        case .operation: return "운영"
        case .people: return "인사·조직"
        case .project: return "프로젝트"
        case .finance: return "재정"
        case .unknown: return "기타"
        }
    }
}

extension RuleStatus: BadgeRepresentable {
    var badgeTitle: String {
        switch self {
        case .active: return "시행 중"
        case .scheduled: return "시행 예정"
        case .unknown: return "확인 중"
        }
    }

    var badgeTone: BadgeTone {
        switch self {
        case .active: return .positive
        case .scheduled: return .primary
        case .unknown: return .neutral
        }
    }
}

extension RuleSummary {
    /// "프로젝트 · NativeOps · v1.3"
    var metaText: String { "\(category.title) · \(department) · \(version)" }

    /// "시행 2026.10.20 · 최근 개정 2026.10.11"
    var datesText: String {
        "시행 \(TSFormat.fullDate(effectiveAt)) · 최근 개정 \(TSFormat.fullDate(revisedAt))"
    }

    /// 중요 개정 카드 — "검토 기한 3주 → 2주 · 10.20 시행 예정"
    var urgentText: String {
        let when = status == .scheduled ? "\(TSFormat.shortDate(effectiveAt)) 시행 예정" : "\(TSFormat.shortDate(effectiveAt)) 시행"
        return [changeSummary, when].compactMap { $0 }.joined(separator: " · ")
    }

    /// 목록 카드 링크
    func linkTitle(now: Date = Date()) -> String {
        status == .scheduled || isRecentlyRevised(now: now) ? "본문 · 변경 내역" : "텍스트 본문 읽기"
    }

    /// 검색 — 제목 · 담당 부서
    func matches(_ query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(keyword) || department.localizedCaseInsensitiveContains(keyword)
    }
}

/// 09-1 상태 칩
enum RuleStatusFilter: CaseIterable, Hashable {
    case all
    case active
    case scheduled
    case recentlyRevised

    var title: String {
        switch self {
        case .all: return "전체 상태"
        case .active: return "시행 중"
        case .scheduled: return "시행 예정"
        case .recentlyRevised: return "최근 개정"
        }
    }

    func matches(_ rule: RuleSummary, now: Date) -> Bool {
        switch self {
        case .all: return true
        case .active: return rule.status == .active
        case .scheduled: return rule.status == .scheduled
        case .recentlyRevised: return rule.isRecentlyRevised(now: now)
        }
    }
}
