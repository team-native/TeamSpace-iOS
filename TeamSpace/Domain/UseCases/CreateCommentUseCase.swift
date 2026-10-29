import Foundation

/// 10-4 댓글 등록 — 1~1,000자
struct CreateCommentUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(postId: Int, draft: CommentDraft) async throws -> PostComment {
        var trimmed = draft
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.body.isEmpty, trimmed.body.count <= CommentDraft.bodyLimit else {
            throw AppError.invalidInput("댓글은 1~\(CommentDraft.bodyLimit)자로 써 주세요.")
        }
        return try await boardRepository.createComment(postId: postId, draft: trimmed)
    }
}
