import Foundation

/// 규칙 문서 등록 · 개정 입력 [Admin] (POST /admin/docs)
struct RuleDraft: Equatable, Sendable {
    static let titleLimit = 60
    static let summaryLimit = 80
    static let noteLimit = 100

    struct Article: Equatable, Identifiable, Sendable {
        let id: UUID
        var title: String
        var body: String
        /// 개정할 때 원래 조항 (바뀐 조항 표시용)
        let original: (title: String, body: String)?

        init(title: String = "", body: String = "", original: (title: String, body: String)? = nil) {
            id = UUID()
            self.title = title
            self.body = body
            self.original = original
        }

        /// 원래 조항과 다르면 개정 조항이에요. (새로 넣은 조항도 포함)
        var isChanged: Bool {
            guard let original else { return true }
            return original.title != title.trimmingCharacters(in: .whitespacesAndNewlines)
                || original.body != body.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        static func == (lhs: Article, rhs: Article) -> Bool {
            lhs.id == rhs.id && lhs.title == rhs.title && lhs.body == rhs.body
        }
    }

    /// 개정이면 원래 문서 slug
    let editingSlug: String?
    var title = ""
    var summary = ""
    var category: RuleCategory = .operation
    /// 서버 분류 글자 — 개정할 때 분류를 그대로 두면 원래 글자를 써요.
    let originalCategoryText: String?
    var effectiveDate: Date
    var articles: [Article] = [Article()]
    /// 개정 사유 (09-3 변경 내역에 남아요)
    var note = ""
    /// 개정하면 전체 알림 보내기
    var notifies = true

    init(now: Date = Date(), calendar: Calendar = .current) {
        editingSlug = nil
        originalCategoryText = nil
        effectiveDate = calendar.startOfDay(for: now)
    }

    /// 개정 — 지금 문서로 채우고, 시행일은 오늘부터예요.
    init(editing detail: RuleDetail, now: Date = Date(), calendar: Calendar = .current) {
        editingSlug = detail.rule.id
        originalCategoryText = detail.categoryText.isEmpty ? nil : detail.categoryText
        effectiveDate = max(calendar.startOfDay(for: now), calendar.startOfDay(for: detail.rule.effectiveAt))
        title = detail.rule.title
        summary = detail.summaryText
        category = detail.rule.category == .unknown ? .operation : detail.rule.category
        articles = detail.articles.map { Article(title: $0.title, body: $0.body, original: ($0.title, $0.body)) }
        if articles.isEmpty { articles = [Article()] }
        originalCategory = category
    }

    private var originalCategory: RuleCategory?

    var isRevision: Bool { editingSlug != nil }

    /// 서버 category — 분류를 그대로 두면 원래 글자, 바꾸면 앱 분류 이름
    var categoryText: String {
        if let originalCategoryText, category == originalCategory { return originalCategoryText }
        switch category {
        case .operation, .unknown: return "운영 규칙"
        case .people: return "인사·조직"
        case .project: return "프로젝트"
        case .finance: return "재무"
        }
    }
}
