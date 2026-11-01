import Foundation

/// GET /workspace/activity · /workspace/posts · /workspace/proposals 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-10 ~ 07-12 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ActivitySummaryDTO: Decodable {
    let unreadNotificationCount: Int
    let submittedDocumentCount: Int
    let postCount: Int
    let inquiryCount: Int

    func toEntity() -> ActivitySummary {
        ActivitySummary(
            unreadNotificationCount: unreadNotificationCount,
            submittedDocumentCount: submittedDocumentCount,
            postCount: postCount,
            inquiryCount: inquiryCount
        )
    }
}

struct MyPostsResponseDTO: Decodable {
    let posts: [PostDTO]
    let comments: [CommentDTO]

    struct PostDTO: Decodable {
        let id: Int
        let title: String
        let createdAt: Date
        let isAnonymous: Bool
        let likeCount: Int
        let commentCount: Int
        let viewCount: Int
        let attachmentCount: Int
    }

    struct CommentDTO: Decodable {
        let id: Int
        let postId: Int
        let postTitle: String
        let body: String
        let createdAt: Date
        let isAnonymous: Bool
        let likeCount: Int
        let replyCount: Int
    }

    func toEntity() -> MyPosts {
        MyPosts(
            posts: posts.map {
                MyPost(
                    id: $0.id, title: $0.title, createdAt: $0.createdAt, isAnonymous: $0.isAnonymous,
                    likeCount: $0.likeCount, commentCount: $0.commentCount, viewCount: $0.viewCount,
                    attachmentCount: $0.attachmentCount
                )
            },
            comments: comments.map {
                MyComment(
                    id: $0.id, postId: $0.postId, postTitle: $0.postTitle, body: $0.body, createdAt: $0.createdAt,
                    isAnonymous: $0.isAnonymous, likeCount: $0.likeCount, replyCount: $0.replyCount
                )
            }
        )
    }
}

struct MyProposalListResponseDTO: Decodable {
    let list: [ProposalDTO]

    struct ProposalDTO: Decodable {
        let id: Int
        let category: String
        let title: String
        let body: String
        let authorName: String
        let createdAt: Date
        let status: ProposalStatus
        let recommendCount: Int
        let commentCount: Int
    }

    func toEntity() -> [MyProposal] {
        list.map {
            MyProposal(
                id: $0.id, category: $0.category, title: $0.title, body: $0.body, authorName: $0.authorName,
                createdAt: $0.createdAt, status: $0.status, recommendCount: $0.recommendCount,
                commentCount: $0.commentCount
            )
        }
    }
}
