import Foundation

/// 12-3 임시 저장 — 빈 글은 저장하지 않아요.
struct ProposalDraftUseCase {
    private let proposalDraftRepository: ProposalDraftRepository

    init(proposalDraftRepository: ProposalDraftRepository) {
        self.proposalDraftRepository = proposalDraftRepository
    }

    func fetch() -> ProposalDraft? {
        proposalDraftRepository.fetch()
    }

    /// 저장했으면 true
    @discardableResult
    func save(_ draft: ProposalDraft) -> Bool {
        guard !draft.isEmpty else { return false }
        proposalDraftRepository.save(draft)
        return true
    }
}
