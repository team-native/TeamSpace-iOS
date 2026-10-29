import Foundation

/// 10-10 신고 — 내 글은 신고할 수 없어요.
struct ReportPostUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(post: PostSummary, reason: PostReportReason) async throws {
        guard !post.isMine else { throw AppError.forbidden("내 글은 신고할 수 없어요.") }
        try await boardRepository.report(postId: post.id, reason: reason)
    }
}
