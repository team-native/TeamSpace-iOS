import Foundation

/// 10-2 글 수정 — 게시하기와 같은 기준으로 확인하고 같은 글을 고쳐요. (PATCH /posts/{id})
struct UpdatePostUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(postId: Int, _ draft: PostDraft) async throws {
        try await boardRepository.updatePost(id: postId, try CreatePostUseCase.validated(draft))
    }
}

extension PostDraft {
    /// 상세에서 불러온 내 글로 글쓰기 칸을 채워요.
    init(editing detail: PostDetail) {
        self.init()
        isAnonymous = detail.post.isAnonymous
        category = PostCategory.selectable.contains(detail.post.category) ? detail.post.category : nil
        title = detail.post.title
        body = detail.body
        commentPolicy = detail.commentPolicy == .unknown ? (detail.post.isAnonymous ? .anonymous : .realName) : detail.commentPolicy
    }
}
