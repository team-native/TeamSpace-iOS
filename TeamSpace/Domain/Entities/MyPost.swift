import Foundation

/// 07-10 내가 쓴 게시글 — 익명 글도 본인에게는 보여요.
struct MyPost: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let createdAt: Date
    /// 공개 화면에 익명으로 보이는 글
    let isAnonymous: Bool
    let likeCount: Int
    let commentCount: Int
    let viewCount: Int
    let attachmentCount: Int
}

/// 07-10 내가 쓴 댓글
struct MyComment: Equatable, Identifiable, Sendable {
    let id: Int
    let postId: Int
    let postTitle: String
    let body: String
    let createdAt: Date
    let isAnonymous: Bool
    let likeCount: Int
    let replyCount: Int
}

/// 07-10 글 · 댓글 묶음
struct MyPosts: Equatable, Sendable {
    let posts: [MyPost]
    let comments: [MyComment]
}
