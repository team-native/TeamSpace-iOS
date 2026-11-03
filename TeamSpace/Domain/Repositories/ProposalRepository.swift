import Foundation

/// 12 운영 제안 저장소 (TeamSpace-backend develop `community.py` 운영 제안)
protocol ProposalRepository: Sendable {
    /// GET /proposals — 12-1b 전체 운영 제안 (최신순, 커서 페이지)
    func fetchProposals(cursor: String?, limit: Int) async throws -> CursorPage<ProposalSummary>
    /// GET /proposals/{proposalId} — 12-2b 상세
    func fetchProposal(id: Int) async throws -> ProposalDetail
    /// POST /proposals/{proposalId}/recommend — 추천 켜기 · 끄기 (1인 1회)
    func toggleRecommend(proposalId: Int) async throws -> ProposalRecommend
    /// POST /proposals/{proposalId}/comments — 댓글 등록
    func addComment(proposalId: Int, body: String, isAnonymous: Bool) async throws -> ProposalComment
    /// POST /proposals — 12-3 제안 올리기 (접수 상태로 시작)
    func create(_ draft: ProposalDraft) async throws -> ProposalSummary
    /// PATCH /admin/proposals/{proposalId} — 담당 부서 · Admin 처리 (상태 · 공식 답변)
    func manage(proposalId: Int, status: ProposalStatus, answer: String?) async throws
}
