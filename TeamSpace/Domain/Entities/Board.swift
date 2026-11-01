import Foundation

/// 10-1 팀 게시판 — 고정 공지 · 이번 주 인기글 · 내가 남긴 기록 (게시글 목록은 페이지로 따로 받아요)
struct Board: Equatable, Sendable {
    let pinnedNotices: [NoticeSummary]
    let popularPosts: [PostSummary]
    /// 아래 "내가 남긴 기록" — 07-1 내 공간과 같은 모양. 못 받으면 카드만 숨겨요.
    let myRecord: WorkspaceRecords?
}

/// GET /posts 조건 — 서버가 분류 · 기간 · 정렬을 걸러서 페이지로 줘요.
struct PostListQuery: Equatable, Sendable {
    enum Sort: Equatable, Sendable {
        case latest
        case likes
    }

    enum Period: Equatable, Sendable {
        case today
        case week
        case month
        case all
        /// 시작일 · 종료일 (날짜만 봐요)
        case range(from: Date, to: Date)
    }

    var category: PostCategory?
    var period: Period = .week
    var sort: Sort = .latest
    var keyword: String?
}

/// 10-12 게시글 검색 결과 — 공지와 게시글을 함께 보여줘요.
struct BoardSearchResult: Equatable, Sendable {
    let notices: [NoticeSummary]
    let posts: [PostSummary]

    var count: Int { notices.count + posts.count }
    var isEmpty: Bool { count == 0 }

    static let empty = BoardSearchResult(notices: [], posts: [])
}
