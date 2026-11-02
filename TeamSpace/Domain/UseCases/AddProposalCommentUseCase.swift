import Foundation

/// 12-2b 댓글 등록 — 1~500자, 등록하면 목록 끝에 붙여요.
struct AddProposalCommentUseCase {
    static let bodyLimit = 500

    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    func execute(_ detail: ProposalDetail, body: String, isAnonymous: Bool) async throws -> ProposalDetail {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= Self.bodyLimit else {
            throw AppError.invalidInput("댓글은 1~\(Self.bodyLimit)자로 써 주세요.")
        }
        let created = try await proposalRepository.addComment(proposalId: detail.proposal.id, body: trimmed, isAnonymous: isAnonymous)
        // 내 제안에 단 댓글이면 제안자 댓글이에요.
        let comment = ProposalComment(
            id: created.id, authorName: created.authorName, isAnonymous: created.isAnonymous,
            isProposer: created.isProposer || detail.proposal.isMine, isMine: true,
            body: created.body, createdAt: created.createdAt
        )
        var updated = detail
        updated.comments.append(comment)
        updated.proposal.commentCount += 1
        return updated
    }
}
