import Foundation

/// 13 통합 검색 저장소
protocol SearchRepository: Sendable {
    /// GET /search?query=&type=ALL — 권한 안에서 문서 · 규정 · 프로젝트 · 팀원 · 공개 글 · 운영 제안을 찾아요.
    /// 익명 글 · 익명 제안, 재무 문서(권한 없을 때)는 서버에서 빠져요.
    func search(query: String) async throws -> SearchResult
}
