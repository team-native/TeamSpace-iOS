import Foundation

/// 12-3 제안 올리기 — 부서 · 제목 · 내용을 확인하고, 올리면 임시 저장은 지워요.
struct CreateProposalUseCase {
    private let proposalRepository: ProposalRepository
    private let proposalDraftRepository: ProposalDraftRepository

    init(proposalRepository: ProposalRepository, proposalDraftRepository: ProposalDraftRepository) {
        self.proposalRepository = proposalRepository
        self.proposalDraftRepository = proposalDraftRepository
    }

    func execute(_ draft: ProposalDraft) async throws -> ProposalSummary {
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ProposalDraft.departments.contains(trimmed.department) else {
            throw AppError.invalidInput("대상 부서를 골라 주세요.")
        }
        guard !trimmed.title.isEmpty, trimmed.title.count <= ProposalDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(ProposalDraft.titleLimit)자로 써 주세요.")
        }
        guard !trimmed.body.isEmpty, trimmed.body.count <= ProposalDraft.bodyLimit else {
            throw AppError.invalidInput("내용은 1~\(ProposalDraft.bodyLimit)자로 써 주세요.")
        }
        let proposal = try await proposalRepository.create(trimmed)
        proposalDraftRepository.clear()
        return proposal
    }
}
