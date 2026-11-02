import Foundation

/// 문서함 저장소 — TeamSpace-backend `/docs`
protocol LibraryRepository: Sendable {
    /// GET /docs — 문서 목록 + 최근 개정된 규칙
    func fetchLibrary() async throws -> LibraryOverview
    /// GET /docs?q= — 제목 · 요약에서 검색
    func searchLibrary(keyword: String) async throws -> [LibraryDocument]
    /// GET /docs/{slug} — 템플릿 본문과 작성 항목
    func fetchTemplate(id: String) async throws -> LibraryTemplate
}
