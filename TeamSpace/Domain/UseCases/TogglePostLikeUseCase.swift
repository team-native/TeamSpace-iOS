import Foundation

/// 10-3 공감 — 서버 결과로 공감 여부와 수를 바꿔요.
struct TogglePostLikeUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(_ detail: PostDetail) async throws -> PostDetail {
        let like = try await boardRepository.toggleLike(postId: detail.post.id)
        var updated = detail
        updated.isLiked = like.isLiked
        updated.post.likeCount = like.likeCount
        return updated
    }

    /// 10-3b 댓글 공감 — 그 댓글만 바꿔요.
    func execute(_ detail: PostDetail, commentId: Int) async throws -> PostDetail {
        let like = try await boardRepository.toggleCommentLike(postId: detail.post.id, commentId: commentId)
        var updated = detail
        if let index = updated.comments.firstIndex(where: { $0.id == commentId }) {
            updated.comments[index].isLiked = like.isLiked
            updated.comments[index].likeCount = like.likeCount
        }
        return updated
    }
}
