import Foundation

/// 10-3 게시글 상세 — 댓글은 오래된 순
struct FetchPostDetailUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(id: Int) async throws -> PostDetail {
        var detail = try await boardRepository.fetchPost(id: id)
        detail.comments.sort { $0.createdAt < $1.createdAt }
        return detail
    }
}
