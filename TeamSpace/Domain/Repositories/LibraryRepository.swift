import Foundation

/// 문서함 저장소
/// 명세서에 문서함 API 가 없어 경로와 응답을 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol LibraryRepository: Sendable {
    /// GET /library — 문서 목록 + 최근 개정된 규칙
    func fetchLibrary() async throws -> LibraryOverview
    /// GET /library/search?keyword= — 제목 · 요약 · 본문에서 검색. 본문 일부(excerpt)를 함께 돌려줘요.
    func searchLibrary(keyword: String) async throws -> [LibraryDocument]
    /// GET /library/templates/{id} — 임시 경로, 백엔드 확정 필요
    func fetchTemplate(id: Int) async throws -> LibraryTemplate
}
