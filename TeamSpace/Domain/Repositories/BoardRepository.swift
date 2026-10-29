import Foundation

/// 10 팀 게시판 저장소
/// 명세서에서 게시판 응답 예시를 찾지 못해 경로 · 필드는 Figma 10 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol BoardRepository: Sendable {
    /// GET /posts — 고정 공지 · 게시글 · 내가 남긴 기록
    func fetchBoard() async throws -> Board
    /// GET /posts/search?keyword= — 10-12 공지 · 게시글 검색
    func search(keyword: String) async throws -> BoardSearchResult
}
