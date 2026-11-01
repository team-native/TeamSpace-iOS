import Foundation

/// 06-2 최근 검색어 — 최근 것이 앞, 같은 검색어는 한 번만, 최대 `limit` 개
struct RecentSearchUseCase {
    static let limit = 5

    private let recentSearchRepository: RecentSearchRepository

    init(recentSearchRepository: RecentSearchRepository) {
        self.recentSearchRepository = recentSearchRepository
    }

    func fetch() -> [String] {
        recentSearchRepository.fetch()
    }

    /// 검색어를 기록하고 바뀐 목록을 돌려줘요.
    @discardableResult
    func record(_ keyword: String) -> [String] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fetch() }
        let keywords = Array(([trimmed] + fetch().filter { $0 != trimmed }).prefix(Self.limit))
        recentSearchRepository.save(keywords)
        return keywords
    }
}
