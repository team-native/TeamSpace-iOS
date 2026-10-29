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
}
