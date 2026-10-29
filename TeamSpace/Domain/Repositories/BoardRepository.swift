import Foundation

/// 10 팀 게시판 저장소
/// 명세서에서 게시판 응답 예시를 찾지 못해 경로 · 필드는 Figma 10 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol BoardRepository: Sendable {
    /// GET /posts — 고정 공지 · 게시글 · 내가 남긴 기록
    func fetchBoard() async throws -> Board
    /// GET /posts/search?keyword= — 10-12 공지 · 게시글 검색
    func search(keyword: String) async throws -> BoardSearchResult
    /// GET /posts/{postId} — 10-3 본문 · 댓글 (조회 수가 1 올라가요)
    func fetchPost(id: Int) async throws -> PostDetail
    /// POST /posts/{postId}/like — 공감 켜기 · 끄기
    func toggleLike(postId: Int) async throws -> PostLike
    /// POST /posts/{postId}/reports — 10-10 신고
    func report(postId: Int, reason: PostReportReason) async throws
    /// DELETE /posts/{postId} — 10-8 내 글 삭제
    func deletePost(id: Int) async throws
}
