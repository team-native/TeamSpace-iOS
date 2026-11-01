import Foundation

/// 12 운영 제안 저장소
/// 명세서에서 응답 예시를 찾지 못해 경로 · 필드는 Figma 12 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol ProposalRepository: Sendable {
    /// GET /proposals — 12-1b 전체 운영 제안
    func fetchProposals() async throws -> [ProposalSummary]
    /// GET /proposals/{proposalId} — 12-2b 상세 (조회 수가 1 올라가요)
    func fetchProposal(id: Int) async throws -> ProposalDetail
    /// POST /proposals/{proposalId}/recommend — 추천 켜기 · 끄기 (1인 1회)
    func toggleRecommend(proposalId: Int) async throws -> ProposalRecommend
    /// POST /proposals/{proposalId}/comments — 댓글 등록
    func addComment(proposalId: Int, body: String, isAnonymous: Bool) async throws -> ProposalComment
}
