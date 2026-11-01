import Foundation

/// 13 통합 검색 — 서버 규칙대로 2자 이상일 때만 물어봐요.
struct SearchAllUseCase {
    static let minimumLength = 2

    private let searchRepository: SearchRepository

    init(searchRepository: SearchRepository) {
        self.searchRepository = searchRepository
    }

    /// 2자 미만이면 nil (검색하지 않음)
    func execute(query: String) async throws -> SearchResult? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumLength else { return nil }
        return try await searchRepository.search(query: trimmed)
    }
}
