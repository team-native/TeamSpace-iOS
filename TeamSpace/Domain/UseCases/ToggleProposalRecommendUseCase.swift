import Foundation

/// 12-2b 추천 — 1인 1회, 다시 누르면 취소
struct ToggleProposalRecommendUseCase {
    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    func execute(_ detail: ProposalDetail) async throws -> ProposalDetail {
        let result = try await proposalRepository.toggleRecommend(proposalId: detail.proposal.id)
        var updated = detail
        updated.isRecommended = result.isRecommended
        updated.proposal.recommendCount = result.recommendCount
        return updated
    }
}
