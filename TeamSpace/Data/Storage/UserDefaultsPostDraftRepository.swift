import Foundation

/// 10-2 임시 저장 글을 기기에 저장합니다. (사진은 저장하지 않아요)
final class UserDefaultsPostDraftRepository: PostDraftRepository, @unchecked Sendable {
    static let key = "board.postDraft.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> PostDraft? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(PostDraft.self, from: data)
    }

    func save(_ draft: PostDraft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
