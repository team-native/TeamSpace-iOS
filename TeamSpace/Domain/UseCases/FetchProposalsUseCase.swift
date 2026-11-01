import Foundation

/// 12-1b 운영 제안 목록 — 기본은 최신순
struct FetchProposalsUseCase {
    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    func execute() async throws -> [ProposalSummary] {
        try await proposalRepository.fetchProposals().sorted { $0.createdAt > $1.createdAt }
    }
}
