import Foundation
import Observation

/// 07-10 내가 쓴 게시글 · 댓글
@Observable
@MainActor
final class MyPostsViewModel {
    private(set) var state: ViewState<MyPosts> = .idle
    var tab: MyPostsTab = .posts
    let userName: String

    private let fetchMyPostsUseCase: FetchMyPostsUseCase

    init(userName: String, fetchMyPostsUseCase: FetchMyPostsUseCase) {
        self.userName = userName
        self.fetchMyPostsUseCase = fetchMyPostsUseCase
    }

    var posts: [MyPost] { state.value?.posts ?? [] }
    var comments: [MyComment] { state.value?.comments ?? [] }

    /// "글 3" / "댓글 4"
    func title(for tab: MyPostsTab) -> String {
        switch tab {
        case .posts: return "글 \(posts.count)"
        case .comments: return "댓글 \(comments.count)"
        }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchMyPostsUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.posts.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
