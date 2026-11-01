import Foundation

/// 게시글 분류 (Figma 10-1 수정본: 자유 · 질문 · 정보공유)
enum PostCategory: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case free = "FREE"
    case question = "QUESTION"
    case info = "INFO"
    case unknown = "UNKNOWN"

    static let unknownCase: PostCategory = .unknown
    static let selectable: [PostCategory] = [.free, .question, .info]
}

/// 10-1 게시글 카드 한 건
struct PostSummary: Equatable, Identifiable, Sendable {
    let id: Int
    let category: PostCategory
    let title: String
    let excerpt: String
    /// 익명 글이면 nil
    let authorName: String?
    /// 예) "Leader"
    let authorRole: String?
    let isAnonymous: Bool
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var viewCount: Int
    let hasImage: Bool
    /// 내가 쓴 글 (익명이어도 본인에게는 알려줘요)
    let isMine: Bool
}

/// 댓글 작성 정책 — 글쓴이가 정한 기본 표시 방식 (10-2 · 10-3)
enum CommentPolicy: String, UnknownCaseDecodable, Encodable, Hashable, Sendable {
    case realName = "REAL_NAME"
    case anonymous = "ANONYMOUS"
    case unknown = "UNKNOWN"

    static let unknownCase: CommentPolicy = .unknown
}

/// 10-3 댓글 한 건
struct PostComment: Equatable, Identifiable, Sendable {
    let id: Int
    /// 익명이면 nil
    let authorName: String?
    let isAnonymous: Bool
    /// 이 글 안에서 익명 작성자에게 붙는 번호 ("익명 1")
    let anonymousNumber: Int?
    /// 글쓴이가 단 댓글
    let isPostAuthor: Bool
    let isMine: Bool
    let body: String
    let createdAt: Date
}

/// 10-3 게시글 상세
struct PostDetail: Equatable, Sendable {
    var post: PostSummary
    let body: String
    let commentPolicy: CommentPolicy
    var isLiked: Bool
    var comments: [PostComment]
}

/// POST /posts/{id}/like 결과
struct PostLike: Equatable, Sendable {
    let isLiked: Bool
    let likeCount: Int
}

/// 10-10 신고 사유
enum PostReportReason: String, CaseIterable, Encodable, Sendable {
    case abuse = "ABUSE"
    case privacy = "PRIVACY"
    case spam = "SPAM"
    case etc = "ETC"
}
