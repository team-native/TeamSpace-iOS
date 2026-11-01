import Foundation

/// 13 통합 검색 저장소
protocol SearchRepository: Sendable {
    /// GET /search?query=&type=ALL — 권한 안에서 문서 · 규정 · 프로젝트 · 팀원 · 공개 글 · 운영 제안을 찾아요.
    /// 익명 글 · 익명 제안, 재무 문서(권한 없을 때)는 서버에서 빠져요.
    /// `cursor` 는 앞 페이지 응답의 `nextCursor` (첫 페이지는 nil), `limit` 은 한 번에 받을 개수예요.
    func search(query: String, cursor: String?, limit: Int) async throws -> SearchResult
}
