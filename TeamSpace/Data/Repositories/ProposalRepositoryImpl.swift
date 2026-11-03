import Foundation

final class ProposalRepositoryImpl: ProposalRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchProposals(cursor: String?, limit: Int) async throws -> CursorPage<ProposalSummary> {
        var query = [URLQueryItem(name: "sort", value: "latest"), URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        let page = try await request(
            Endpoint(method: .get, path: "proposals", queryItems: query),
            as: CursorPageDTO<ServerProposalDTO>.self
        )
        return CursorPage(items: page.items.map { $0.toEntity() }, nextCursor: page.nextCursor)
    }

    func fetchProposal(id: Int) async throws -> ProposalDetail {
        try await request(Endpoint(method: .get, path: "proposals/\(id)"), as: ServerProposalDTO.self).toDetail()
    }

    func toggleRecommend(proposalId: Int) async throws -> ProposalRecommend {
        let dto = try await request(
            Endpoint(method: .post, path: "proposals/\(proposalId)/recommend"),
            as: ServerProposalRecommendDTO.self
        )
        return ProposalRecommend(isRecommended: dto.recommended, recommendCount: dto.recommendCount)
    }

    /// 응답에 작성 시각 · 내 댓글 여부가 없어 지금 시각 · 내 댓글로 채워요. (제안자 여부는 유스케이스가 정해요)
    func addComment(proposalId: Int, body: String, isAnonymous: Bool) async throws -> ProposalComment {
        let endpoint = Endpoint(
            method: .post,
            path: "proposals/\(proposalId)/comments",
            body: ServerProposalCommentRequestDTO(text: body, anonymous: isAnonymous)
        )
        return try await request(endpoint, as: ServerProposalCommentDTO.self).toEntity(proposalAuthor: nil)
    }

    /// 응답은 `{id, status}` 뿐이라 보낸 내용으로 목록 항목을 만들어요.
    func create(_ draft: ProposalDraft) async throws -> ProposalSummary {
        let body = ServerProposalCreateRequestDTO(
            title: draft.title,
            body: draft.body,
            category: draft.department,
            dept: draft.department,
            anonymous: draft.isAnonymous
        )
        let created = try await request(Endpoint(method: .post, path: "proposals", body: body), as: ServerProposalCreatedDTO.self)
        return ProposalSummary(
            id: created.id,
            department: draft.department,
            title: draft.title,
            excerpt: ServerPostItemDTO.excerpt(of: draft.body),
            isAnonymous: draft.isAnonymous,
            authorName: nil,
            createdAt: Date(),
            status: ProposalStatus(serverValue: created.status ?? "접수"),
            recommendCount: 0,
            commentCount: 0,
            isMine: true
        )
    }

    /// 응답 `{id, status, answer}` 은 쓰지 않고, 처리 뒤 상세를 다시 불러와요.
    func manage(proposalId: Int, status: ProposalStatus, answer: String?) async throws {
        let body = ServerProposalManageRequestDTO(status: status.serverValue, answer: answer)
        _ = try await request(Endpoint(method: .patch, path: "admin/proposals/\(proposalId)", body: body), as: EmptyResponseDTO.self)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
