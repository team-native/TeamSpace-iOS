import Foundation

/// 12-2b 내 운영 제안 고치기 · 지우기
/// 고치기는 작성자가 접수 상태일 때만, 지우기는 작성자 · Admin 이 할 수 있어요. (서버 `PATCH` · `DELETE /proposals/{id}`)
struct EditProposalUseCase {
    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    static func canEdit(_ proposal: ProposalSummary) -> Bool {
        proposal.isMine && proposal.status == .received
    }

    static func canDelete(_ proposal: ProposalSummary, user: AuthUser?) -> Bool {
        proposal.isMine || user?.roles.contains(.admin) == true
    }

    /// 고칠 때 처음 채울 내용 — 익명 여부는 그대로예요.
    static func draft(from detail: ProposalDetail) -> ProposalDraft {
        ProposalDraft(
            department: ProposalDraft.chipDepartment(detail.proposal.department),
            title: detail.proposal.title,
            body: detail.body,
            isAnonymous: detail.proposal.isAnonymous
        )
    }

    func update(_ detail: ProposalDetail, draft: ProposalDraft) async throws -> ProposalDetail {
        guard Self.canEdit(detail.proposal) else {
            throw AppError.forbidden(detail.proposal.isMine ? "접수 상태인 제안만 고칠 수 있어요." : "내 제안만 고칠 수 있어요.")
        }
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
        return try await proposalRepository.update(proposalId: detail.proposal.id, trimmed)
    }

    func delete(_ proposal: ProposalSummary, user: AuthUser?) async throws {
        guard Self.canDelete(proposal, user: user) else { throw AppError.forbidden("내 제안만 지울 수 있어요.") }
        try await proposalRepository.delete(proposalId: proposal.id)
    }
}
