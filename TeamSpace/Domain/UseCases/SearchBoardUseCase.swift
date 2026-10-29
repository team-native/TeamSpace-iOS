import Foundation

/// 10-12 게시글 검색 — 빈 검색어는 요청하지 않고, 게시글은 최신순
struct SearchBoardUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(keyword: String) async throws -> BoardSearchResult {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        let result = try await boardRepository.search(keyword: trimmed)
        return BoardSearchResult(
            notices: result.notices,
            posts: result.posts.sorted { $0.createdAt > $1.createdAt }
        )
    }
}
