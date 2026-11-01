import Foundation

/// 13 통합 검색 결과 묶음 (백엔드 `groups` 키)
enum SearchCategory: String, CaseIterable, Hashable, Sendable {
    case documents
    case projects
    case people
    case posts
    case proposals
}

/// 13 통합 검색 결과 한 건 — 분류마다 채워지는 값이 달라요.
struct SearchHit: Equatable, Identifiable, Sendable {
    let category: SearchCategory
    /// 서버 id (문자열). 앱 화면 이동은 숫자 id 를 쓰므로 `targetId` 로 바꿔 써요.
    let serverId: String
    let title: String
    let snippet: String
    let createdAt: Date?
    /// 문서 · 규정 — 예) RULE · TEMPLATE · PROJECT
    var documentType: String?
    var version: String?
    /// 게시글
    var author: String?
    var commentCount: Int?
    /// 운영 제안
    var proposalStatus: ProposalStatus?
    var likeCount: Int?
    /// 프로젝트
    var department: String?
    var pmName: String?
    var progress: Int?

    var id: String { "\(category.rawValue)-\(serverId)" }
    var targetId: Int? { Int(serverId) }
}

/// GET /search 응답 — 이번 페이지 결과 + 분류별 전체 개수
struct SearchResult: Equatable, Sendable {
    let query: String
    let items: [SearchHit]
    let counts: [SearchCategory: Int]
    let nextCursor: String?

    var totalCount: Int { counts.values.reduce(0, +) }
    var isEmpty: Bool { items.isEmpty }
}
