import Foundation

/// 10-3 댓글 고치기 · 지우기 — 내 댓글은 고치고 지울 수 있고, Admin 은 남의 댓글도 지울 수 있어요.
struct ManagePostCommentUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    /// 고친 댓글을 넣은 상세를 돌려줘요. (작성자 · 공감 표시는 그대로)
    func update(_ detail: PostDetail, commentId: Int, text: String) async throws -> PostDetail {
        guard let index = detail.comments.firstIndex(where: { $0.id == commentId }) else {
            throw AppError.invalidInput("댓글을 찾을 수 없어요.")
        }
        guard detail.comments[index].isMine else { throw AppError.forbidden("내 댓글만 고칠 수 있어요.") }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= CommentDraft.bodyLimit else {
            throw AppError.invalidInput("댓글은 1~\(CommentDraft.bodyLimit)자로 써 주세요.")
        }
        let saved = try await boardRepository.updateComment(postId: detail.post.id, commentId: commentId, text: trimmed)
        var updated = detail
        updated.comments[index].body = saved.body.isEmpty ? trimmed : saved.body
        return updated
    }

    /// 지운 댓글을 뺀 상세를 돌려줘요.
    func delete(_ detail: PostDetail, commentId: Int, isAdmin: Bool) async throws -> PostDetail {
        guard let comment = detail.comments.first(where: { $0.id == commentId }) else {
            throw AppError.invalidInput("댓글을 찾을 수 없어요.")
        }
        guard comment.isMine || isAdmin else { throw AppError.forbidden("내 댓글만 지울 수 있어요.") }
        try await boardRepository.deleteComment(postId: detail.post.id, commentId: commentId)
        var updated = detail
        updated.comments.removeAll { $0.id == commentId }
        updated.post.commentCount = max(0, updated.post.commentCount - 1)
        return updated
    }
}

/// 10-8 게시글 상단 고정 · 해제 (Admin)
struct PinPostUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(_ detail: PostDetail, isPinned: Bool, isAdmin: Bool) async throws -> PostDetail {
        guard isAdmin else { throw AppError.forbidden("게시글 고정은 관리자만 할 수 있어요.") }
        var updated = detail
        updated.post.isPinned = try await boardRepository.setPinned(postId: detail.post.id, isPinned: isPinned)
        return updated
    }
}
