import Foundation

/// 10-1 팀 게시판 위쪽 — 고정 공지 · 이번 주 인기글 · 내가 남긴 기록을 한 번에 받아요.
/// 게시글 목록은 `FetchPostsUseCase` 로 페이지마다 받아요.
struct FetchBoardUseCase {
    static let pinnedLimit = 5
    static let popularLimit = 3

    private let boardRepository: BoardRepository
    private let workspaceRepository: WorkspaceRepository

    init(boardRepository: BoardRepository, workspaceRepository: WorkspaceRepository) {
        self.boardRepository = boardRepository
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> Board {
        async let pinned = boardRepository.fetchPinnedNotices(limit: Self.pinnedLimit)
        async let popular = boardRepository.fetchPosts(
            PostListQuery(period: .week, sort: .likes),
            cursor: nil,
            limit: Self.popularLimit
        )
        async let home = try? workspaceRepository.fetchHome()
        return Board(
            pinnedNotices: try await pinned,
            popularPosts: try await popular.items,
            myRecord: await home?.records
        )
    }
}

/// 10-1 게시글 목록 한 페이지
struct FetchPostsUseCase {
    private let boardRepository: BoardRepository
    let pageSize: Int

    init(boardRepository: BoardRepository, pageSize: Int = 20) {
        self.boardRepository = boardRepository
        self.pageSize = pageSize
    }

    func execute(_ query: PostListQuery, cursor: String?) async throws -> CursorPage<PostSummary> {
        try await boardRepository.fetchPosts(query, cursor: cursor, limit: pageSize)
    }
}
