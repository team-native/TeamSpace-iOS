import Foundation

/// Mock 저장소 · 글 작성 응답에 쓰는 앱 쪽 게시글 모양 (목록은 `ServerPostItemDTO`)
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
