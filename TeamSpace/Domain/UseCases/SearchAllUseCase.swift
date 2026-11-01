import Foundation

/// 13 통합 검색 — 서버 규칙대로 2자 이상일 때만 물어봐요.
struct SearchAllUseCase {
    static let minimumLength = 2

    /// 서버 기본값과 같은 한 페이지 개수 (최대 100)
    static let defaultPageSize = 50

    private let searchRepository: SearchRepository
    private let pageSize: Int

    init(searchRepository: SearchRepository, pageSize: Int = Self.defaultPageSize) {
        self.searchRepository = searchRepository
        self.pageSize = pageSize
    }

    /// 2자 미만이면 nil (검색하지 않음). 다음 페이지는 앞 응답의 `nextCursor` 를 넘겨요.
    func execute(query: String, cursor: String? = nil) async throws -> SearchResult? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumLength else { return nil }
        return try await searchRepository.search(query: trimmed, cursor: cursor, limit: pageSize)
    }
}
