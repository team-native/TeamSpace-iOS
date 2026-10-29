import Foundation

/// GET /posts · /posts/search 응답의 `data`
/// 명세서에서 응답 예시를 찾지 못해 Figma 10 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct BoardResponseDTO: Decodable {
    let pinnedNotices: [NoticeSummaryDTO]
    let posts: [PostSummaryDTO]
    let myRecord: WorkspaceHomeResponseDTO.RecordsDTO

    func toEntity() -> Board {
        Board(pinnedNotices: pinnedNotices.map { $0.toEntity() }, posts: posts.map { $0.toEntity() }, myRecord: myRecord.toEntity())
    }
}

struct BoardSearchResponseDTO: Codable {
    let notices: [NoticeSummaryDTO]
    let posts: [PostSummaryDTO]

    func toEntity() -> BoardSearchResult {
        BoardSearchResult(notices: notices.map { $0.toEntity() }, posts: posts.map { $0.toEntity() })
    }
}

struct PostSummaryDTO: Codable {
    let id: Int
    let category: PostCategory
    let title: String
    let excerpt: String
    let authorName: String?
    let authorRole: String?
    let isAnonymous: Bool
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var viewCount: Int
    let hasImage: Bool
    let isMine: Bool

    func toEntity() -> PostSummary {
        PostSummary(
            id: id, category: category, title: title, excerpt: excerpt,
            authorName: isAnonymous ? nil : authorName, authorRole: isAnonymous ? nil : authorRole,
            isAnonymous: isAnonymous, createdAt: createdAt, likeCount: likeCount, commentCount: commentCount,
            viewCount: viewCount, hasImage: hasImage, isMine: isMine
        )
    }
}

struct NoticeSummaryDTO: Codable {
    let id: Int
    let category: NoticeCategory
    let title: String
    let summary: String?
    let updatedAt: Date
    let isPinned: Bool
    let isImportant: Bool

    func toEntity() -> NoticeSummary {
        NoticeSummary(
            id: id, category: category, title: title, summary: summary,
            updatedAt: updatedAt, isPinned: isPinned, isImportant: isImportant
        )
    }
}

/// GET /posts/{id} 응답의 `data`
struct PostDetailDTO: Codable {
    let post: PostSummaryDTO
    let body: String
    let commentPolicy: CommentPolicy
    let isLiked: Bool
    let comments: [PostCommentDTO]

    func toEntity() -> PostDetail {
        PostDetail(
            post: post.toEntity(), body: body, commentPolicy: commentPolicy,
            isLiked: isLiked, comments: comments.map { $0.toEntity() }
        )
    }
}

struct PostCommentDTO: Codable {
    let id: Int
    let authorName: String?
    let isAnonymous: Bool
    let anonymousNumber: Int?
    let isPostAuthor: Bool
    let isMine: Bool
    let body: String
    let createdAt: Date

    func toEntity() -> PostComment {
        PostComment(
            id: id, authorName: isAnonymous ? nil : authorName, isAnonymous: isAnonymous,
            anonymousNumber: anonymousNumber, isPostAuthor: isPostAuthor, isMine: isMine,
            body: body, createdAt: createdAt
        )
    }
}

/// POST /posts/{id}/like 응답의 `data`
struct PostLikeResponseDTO: Codable {
    let isLiked: Bool
    let likeCount: Int
}

/// POST /posts/{id}/reports 요청
struct PostReportRequestDTO: Codable {
    let reason: String
}

/// POST /posts 요청 — 사진은 base64 문자열 (업로드 방식은 백엔드와 맞춰야 함)
struct PostCreateRequestDTO: Codable {
    let isAnonymous: Bool
    let category: PostCategory
    let title: String
    let body: String
    let commentPolicy: CommentPolicy
    let images: [String]
}

/// POST /posts/{id}/comments 요청
struct CommentCreateRequestDTO: Codable {
    let body: String
    let isAnonymous: Bool
}
