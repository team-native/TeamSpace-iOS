import Foundation

/// 10 팀 게시판 저장소
/// 목록 · 고정 공지 · 검색은 TeamSpace-backend develop `app/api/community.py` 기준이에요.
/// 상세 · 작성 · 댓글은 아직 Figma 10 기준 경로예요. (다음 API 맞추기 묶음)
protocol BoardRepository: Sendable {
    /// GET /posts?category&sort&period&from&to&q&cursor&limit — `{items, nextCursor}`
    func fetchPosts(_ query: PostListQuery, cursor: String?, limit: Int) async throws -> CursorPage<PostSummary>
    /// GET /notices?pinned=true — 10-1 고정 공지
    func fetchPinnedNotices(limit: Int) async throws -> [NoticeSummary]
    /// GET /posts?q= + GET /notices?q= — 10-12 공지 · 게시글 검색
    func search(keyword: String) async throws -> BoardSearchResult
    /// GET /posts/{postId} — 10-3 본문 · 댓글 (조회 수가 1 올라가요)
    func fetchPost(id: Int) async throws -> PostDetail
    /// POST /posts/{postId}/like — 공감 켜기 · 끄기
    func toggleLike(postId: Int) async throws -> PostLike
    /// POST /posts/{id}/comments/{commentId}/like — 댓글 공감 토글
    func toggleCommentLike(postId: Int, commentId: Int) async throws -> PostLike
    /// POST /posts/{postId}/reports — 10-10 신고
    func report(postId: Int, reason: PostReportReason) async throws
    /// DELETE /posts/{postId} — 10-8 내 글 삭제
    func deletePost(id: Int) async throws
    /// POST /posts — 10-2 게시 (사진은 JPG · PNG 데이터)
    func createPost(_ draft: PostDraft, images: [Data]) async throws -> PostSummary
    /// POST /posts/{postId}/comments — 10-4 댓글 등록
    func createComment(postId: Int, draft: CommentDraft) async throws -> PostComment
}
