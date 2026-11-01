import Foundation

/// 12-3 임시 저장 제안을 기기에 저장합니다.
final class UserDefaultsProposalDraftRepository: ProposalDraftRepository, @unchecked Sendable {
    static let key = "proposal.draft.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> ProposalDraft? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(ProposalDraft.self, from: data)
    }

    func save(_ draft: ProposalDraft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
