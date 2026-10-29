import Foundation

/// 10-8 삭제하기 — 내 글만 지울 수 있어요.
struct DeletePostUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(post: PostSummary) async throws {
        guard post.isMine else { throw AppError.forbidden("내 글만 삭제할 수 있어요.") }
        try await boardRepository.deletePost(id: post.id)
    }
}
