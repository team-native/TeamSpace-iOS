import Foundation

/// 12-2c 담당자 처리 — Admin 이거나 내 부서가 제안 담당 부서일 때만 (서버 403 이 최종 기준)
struct ManageProposalUseCase {
    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    static func canManage(_ proposal: ProposalSummary, user: AuthUser?, department: String?) -> Bool {
        guard let user else { return false }
        if user.roles.contains(.admin) { return true }
        guard let department, !department.isEmpty else { return false }
        return department == proposal.department
    }

    func execute(_ detail: ProposalDetail, draft: ProposalManageDraft) async throws -> ProposalDetail {
        let trimmed = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.action.needsBody {
            guard !trimmed.isEmpty else {
                throw AppError.invalidInput(draft.action == .answer ? "공식 답변을 입력해 주세요." : "반려 사유를 입력해 주세요.")
            }
            guard trimmed.count <= ProposalManageDraft.bodyLimit else {
                throw AppError.invalidInput("\(ProposalManageDraft.bodyLimit)자 안으로 써 주세요.")
            }
        } else if draft.action.status == detail.proposal.status {
            throw AppError.invalidInput("이미 \(draft.action.title) 상태예요.")
        }
        try await proposalRepository.manage(
            proposalId: detail.proposal.id,
            status: draft.action.status,
            answer: draft.action.needsBody ? trimmed : nil
        )
        return try await proposalRepository.fetchProposal(id: detail.proposal.id)
    }
}
