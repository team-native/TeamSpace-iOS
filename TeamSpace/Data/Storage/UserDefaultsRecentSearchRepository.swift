import Foundation

/// 최근 검색어를 기기에 저장합니다. (민감 정보가 아니라 UserDefaults 사용)
final class UserDefaultsRecentSearchRepository: RecentSearchRepository, @unchecked Sendable {
    static let libraryKey = "library.recentSearches.v1"

    private let defaults: UserDefaults
    private let key: String

    /// - Parameter seed: 저장된 값이 한 번도 없을 때 보여줄 기본 검색어 (Mock 서버용)
    init(defaults: UserDefaults = .standard, key: String = libraryKey, seed: [String] = []) {
        self.defaults = defaults
        self.key = key
        if defaults.object(forKey: key) == nil, !seed.isEmpty {
            defaults.set(seed, forKey: key)
        }
    }

    func fetch() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(_ keywords: [String]) {
        defaults.set(keywords, forKey: key)
    }
}
