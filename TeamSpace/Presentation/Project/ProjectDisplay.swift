import SwiftUI

extension ProjectSummary {
    /// "NativeLab · PM 이시우 · 6명"
    var metaText: String {
        "\(department) · PM \(pmName) · \(memberCount)명"
    }

    /// "2026.07.01 – 11.30"
    var periodText: String {
        "\(TSFormat.fullDate(startDate)) – \(TSFormat.shortDate(endDate))"
    }

    /// 목록 카드 설명 — "독서 기록과 … 앱. 2026.07.01–11.30 · iOS 1명 모집"
    var cardDescription: String {
        let tail: String
        if let opening = openings.first {
            tail = "\(opening.role) \(opening.headcount)명 모집"
        } else if status == .completed {
            tail = resultNote ?? "프로젝트 완료"
        } else {
            tail = "모집 마감"
        }
        return "\(summary). \(TSFormat.fullDate(startDate))–\(TSFormat.shortDate(endDate)) · \(tail)"
    }

    /// 카드 아래 링크
    var linkTitle: String {
        if isRecruiting { return "모집 공고 보기" }
        if status == .completed { return "결과와 문서 보기" }
        return "프로젝트 자세히 보기"
    }

    /// 관심 직군 · 검색어가 맞는지
    func matches(_ query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return true }
        return [name, summary, pmName].contains { $0.localizedCaseInsensitiveContains(keyword) }
    }

    func recruitsAny(of roles: [String]) -> Bool {
        openings.contains { opening in
            roles.contains { opening.role.localizedCaseInsensitiveContains($0) || $0.localizedCaseInsensitiveContains(opening.role) }
        }
    }
}

extension ProjectOpening {
    /// "iOS 개발 1명 · 11월 ~ 12월"
    var headline: String {
        "\(title) \(headcount)명 · \(TSFormat.month(startDate)) ~ \(TSFormat.month(endDate))"
    }
}

extension ProjectScheduleChange {
    /// "10.15 14:20 변경"
    var changedText: String {
        "\(TSFormat.shortDate(changedAt)) \(TSFormat.time(changedAt)) 변경"
    }

    /// "10.22 14:00–15:00"
    var beforeText: String {
        "\(TSFormat.shortDate(beforeStart)) \(TSFormat.timeRange(beforeStart, beforeEnd))"
    }

    var afterText: String {
        "\(TSFormat.shortDate(afterStart)) \(TSFormat.timeRange(afterStart, afterEnd))"
    }

    /// 지난 변경 한 줄 — "10.14 14:00 → 15:00 · 논의 자료 보완"
    var summaryText: String {
        let sameDay = Calendar.current.isDate(beforeStart, inSameDayAs: afterStart)
        let after = sameDay ? TSFormat.time(afterStart) : "\(TSFormat.shortDate(afterStart)) \(TSFormat.time(afterStart))"
        return "\(TSFormat.shortDate(beforeStart)) \(TSFormat.time(beforeStart)) → \(after) · \(reason)"
    }
}

extension ProjectMilestone {
    /// "2026.10.23 15:00 · 내 참석 일정"
    var detailText: String {
        let hasTime = Calendar.current.component(.hour, from: date) != 0
        let when = hasTime ? "\(TSFormat.fullDate(date)) \(TSFormat.time(date))" : TSFormat.fullDate(date)
        return [when, note].compactMap { $0 }.joined(separator: " · ")
    }
}

/// 08-1 상태 칩
enum ProjectStatusFilter: CaseIterable, Hashable {
    case all
    case planned
    case inProgress
    case completed

    var status: ProjectRunStatus? {
        switch self {
        case .all: return nil
        case .planned: return .planned
        case .inProgress: return .inProgress
        case .completed: return .completed
        }
    }

    var title: String {
        status?.badgeTitle ?? "전체"
    }
}
