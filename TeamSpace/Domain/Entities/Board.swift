import Foundation

/// 10-1 팀 게시판 — 고정 공지 · 게시글 · 내가 남긴 기록
struct Board: Equatable, Sendable {
    let pinnedNotices: [NoticeSummary]
    let posts: [PostSummary]
    /// 아래 "내가 남긴 기록" — 07-1 내 공간과 같은 모양
    let myRecord: WorkspaceRecords
}

/// 10-12 게시글 검색 결과 — 공지와 게시글을 함께 보여줘요.
struct BoardSearchResult: Equatable, Sendable {
    let notices: [NoticeSummary]
    let posts: [PostSummary]

    var count: Int { notices.count + posts.count }
    var isEmpty: Bool { count == 0 }

    static let empty = BoardSearchResult(notices: [], posts: [])
}
