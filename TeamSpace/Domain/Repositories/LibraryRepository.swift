import Foundation

/// 문서함 저장소
/// 명세서에 문서함 API 가 없어 경로와 응답을 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol LibraryRepository: Sendable {
    /// GET /library — 문서 목록 + 최근 개정된 규칙
    func fetchLibrary() async throws -> LibraryOverview
}
