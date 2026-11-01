import Foundation

final class ProposalRepositoryImpl: ProposalRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchProposals() async throws -> [ProposalSummary] {
        try await request(Endpoint(method: .get, path: "proposals"), as: ProposalListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchProposal(id: Int) async throws -> ProposalDetail {
        try await request(Endpoint(method: .get, path: "proposals/\(id)"), as: ProposalDetailDTO.self).toEntity()
    }

    func toggleRecommend(proposalId: Int) async throws -> ProposalRecommend {
        let dto = try await request(
            Endpoint(method: .post, path: "proposals/\(proposalId)/recommend"),
            as: ProposalRecommendResponseDTO.self
        )
        return ProposalRecommend(isRecommended: dto.isRecommended, recommendCount: dto.recommendCount)
    }

    func addComment(proposalId: Int, body: String, isAnonymous: Bool) async throws -> ProposalComment {
        let endpoint = Endpoint(
            method: .post,
            path: "proposals/\(proposalId)/comments",
            body: ProposalCommentRequestDTO(body: body, isAnonymous: isAnonymous)
        )
        return try await request(endpoint, as: ProposalCommentDTO.self).toEntity()
    }

    func create(_ draft: ProposalDraft) async throws -> ProposalSummary {
        let body = ProposalCreateRequestDTO(
            department: draft.department,
            title: draft.title,
            body: draft.body,
            isAnonymous: draft.isAnonymous
        )
        return try await request(Endpoint(method: .post, path: "proposals", body: body), as: ProposalSummaryDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
