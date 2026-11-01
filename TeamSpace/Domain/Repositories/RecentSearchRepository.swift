import Foundation

/// 최근 검색어 저장소 (기기에만 저장)
protocol RecentSearchRepository: Sendable {
    func fetch() -> [String]
    func save(_ keywords: [String])
}
