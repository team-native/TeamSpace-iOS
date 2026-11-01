import Foundation

/// 07-10 내가 쓴 글 · 댓글 — 최근 작성 순
struct FetchMyPostsUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> MyPosts {
        let result = try await workspaceRepository.fetchMyPosts()
        return MyPosts(
            posts: result.posts.sorted { $0.createdAt > $1.createdAt },
            comments: result.comments.sorted { $0.createdAt > $1.createdAt }
        )
    }
}
