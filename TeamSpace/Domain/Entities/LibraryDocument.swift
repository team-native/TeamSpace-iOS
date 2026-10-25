import Foundation

/// 06 문서함 분류
enum LibraryCategory: String, UnknownCaseDecodable, Hashable, Sendable {
    case rule = "RULE"           // 운영 규칙
    case finance = "FINANCE"     // 재무
    case template = "TEMPLATE"   // 템플릿
    case guide = "GUIDE"         // 가이드
    case unknown = "UNKNOWN"

    static let unknownCase: LibraryCategory = .unknown
}

/// 06-1 · 06-2 문서함 문서 한 건
struct LibraryDocument: Equatable, Identifiable, Sendable {
    let id: Int
    let category: LibraryCategory
    let title: String
    let summary: String
    /// 검색 결과에서 검색어가 들어 있는 부분 (06-2). 목록에서는 nil
    let excerpt: String?
    let updatedAt: Date
}

/// 06-1 상단 배너 — 최근 개정된 규칙
struct LibraryRevision: Equatable, Sendable {
    let documentId: Int
    let title: String
    let effectiveAt: Date
}

/// 06-1 문서함 전체
struct LibraryOverview: Equatable, Sendable {
    let documents: [LibraryDocument]
    let latestRevision: LibraryRevision?

    func count(of category: LibraryCategory) -> Int {
        documents.filter { $0.category == category }.count
    }
}
