import Foundation

/// 10-1 팀 게시판 — 게시글은 최신순
struct FetchBoardUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute() async throws -> Board {
        let board = try await boardRepository.fetchBoard()
        return Board(
            pinnedNotices: board.pinnedNotices,
            posts: board.posts.sorted { $0.createdAt > $1.createdAt },
            myRecord: board.myRecord
        )
    }
}
