import Foundation

/// 12-2b 운영 제안 상세 — 진행 단계 · 댓글은 오래된 순
struct FetchProposalDetailUseCase {
    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    func execute(id: Int) async throws -> ProposalDetail {
        let detail = try await proposalRepository.fetchProposal(id: id)
        return ProposalDetail(
            proposal: detail.proposal,
            body: detail.body,
            viewCount: detail.viewCount,
            isRecommended: detail.isRecommended,
            steps: detail.steps.sorted { $0.reachedAt < $1.reachedAt },
            answer: detail.answer,
            comments: detail.comments.sorted { $0.createdAt < $1.createdAt }
        )
    }
}
