import Foundation

extension PostCategory: BadgeRepresentable {
    var title: String {
        switch self {
        case .free: return "자유"
        case .question: return "질문"
        case .info: return "정보공유"
        case .unknown: return "기타"
        }
    }

    var badgeTitle: String { title }

    var badgeTone: BadgeTone {
        switch self {
        case .free: return .positive
        case .question: return .violet
        case .info: return .amber
        case .unknown: return .neutral
        }
    }
}

/// 제목 · 색은 02-1 홈 공지(HomeDisplay)와 같아요.
extension NoticeCategory: BadgeRepresentable {
    var badgeTitle: String { title }
    var badgeTone: BadgeTone { tone }
}

extension PostSummary {
    /// "익명" / "김민준 · Leader"
    var authorText: String {
        guard !isAnonymous, let name = authorName else { return "익명" }
        guard let role = authorRole, !role.isEmpty else { return name }
        return "\(name) · \(role)"
    }

    /// 10-1 인기글 · 10-12 검색 결과 줄 — "익명 · 추천 33 · 댓글 9"
    var reactionText: String {
        "\(isAnonymous ? "익명" : authorName ?? "익명") · 추천 \(likeCount) · 댓글 \(commentCount)"
    }

    /// 10-12 — "팀 게시판 · 익명 · 10.14 · 추천 18 · 댓글 6"
    func searchMetaText(now: Date = Date()) -> String {
        let author = isAnonymous ? "익명" : authorName ?? "익명"
        return "팀 게시판 · \(author) · \(TSFormat.dayLabel(createdAt, now: now)) · 추천 \(likeCount) · 댓글 \(commentCount)"
    }
}

/// 10-1 기간 칩 — 오늘 · 이번 주(최근 7일) · 이번 달(최근 30일) · 전체 · 기간 설정
enum BoardPeriod: Hashable {
    case today
    case week
    case month
    case all
    case custom(start: Date, end: Date)

    static let presets: [BoardPeriod] = [.today, .week, .month, .all]

    var title: String {
        switch self {
        case .today: return "오늘"
        case .week: return "이번 주"
        case .month: return "이번 달"
        case .all: return "전체"
        case .custom(let start, let end): return "\(TSFormat.shortDate(start)) – \(TSFormat.shortDate(end))"
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    func contains(_ date: Date, now: Date, calendar: Calendar = .current) -> Bool {
        let today = calendar.startOfDay(for: now)
        switch self {
        case .today: return date >= today
        case .week: return date >= today.addingTimeInterval(-6 * 86_400)
        case .month: return date >= today.addingTimeInterval(-29 * 86_400)
        case .all: return true
        case .custom(let start, let end):
            let endOfDay = calendar.startOfDay(for: end).addingTimeInterval(86_400)
            return date >= calendar.startOfDay(for: start) && date < endOfDay
        }
    }
}

/// 10-1 분류 칩 — 전체 · 공지 · 자유 · 질문 · 정보공유
enum BoardFilter: Hashable {
    case all
    case notice
    case category(PostCategory)

    static let allCases: [BoardFilter] = [.all, .notice] + PostCategory.selectable.map { BoardFilter.category($0) }

    var title: String {
        switch self {
        case .all: return "전체"
        case .notice: return "공지"
        case .category(let category): return category.title
        }
    }

    func matches(_ post: PostSummary) -> Bool {
        switch self {
        case .all: return true
        case .notice: return false
        case .category(let category): return post.category == category
        }
    }
}

/// 10-1 정렬
enum BoardSort: CaseIterable, Hashable {
    case latest
    case popular

    var title: String {
        switch self {
        case .latest: return "최신순"
        case .popular: return "인기순"
        }
    }
}
