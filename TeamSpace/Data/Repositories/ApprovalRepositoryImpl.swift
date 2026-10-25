import Foundation

final class ApprovalRepositoryImpl: ApprovalRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMyApprovals() async throws -> [ApprovalItem] {
        try await request(Endpoint(method: .get, path: "approvals/mine"), as: ApprovalListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func fetchReceivedApprovals() async throws -> [ApprovalItem] {
        try await request(Endpoint(method: .get, path: "approvals/received"), as: ApprovalListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func fetchDetail(documentId: Int) async throws -> ApprovalDetail {
        try await request(Endpoint(method: .get, path: "documents/\(documentId)"), as: ApprovalDetailResponseDTO.self)
            .toEntity()
    }

    func decide(approvalId: Int, decision: ApprovalDecision, comment: String?) async throws -> ApprovalDecisionResult {
        let endpoint = Endpoint(
            method: .post,
            path: "approvals/\(approvalId)/decide",
            body: ApprovalDecisionRequestDTO(decision: decision.rawValue, comment: comment)
        )
        return try await request(endpoint, as: ApprovalDecisionResponseDTO.self).toEntity()
    }

    func addComment(documentId: Int, body: String) async throws -> ApprovalComment {
        let endpoint = Endpoint(
            method: .post,
            path: "documents/\(documentId)/comments",
            body: ApprovalCommentRequestDTO(body: body)
        )
        return try await request(endpoint, as: ApprovalCommentDTO.self).toEntity()
    }

    func createDocument(_ draft: DocumentDraft) async throws -> Int {
        let endpoint = Endpoint(method: .post, path: "documents", body: DocumentCreateRequestDTO(draft))
        return try await request(endpoint, as: DocumentCreateResponseDTO.self).documentId
    }

    func submitDocument(documentId: Int) async throws {
        let endpoint = Endpoint(method: .post, path: "documents/\(documentId)/submit")
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    func withdraw(documentId: Int) async throws {
        let endpoint = Endpoint(method: .post, path: "documents/\(documentId)/withdraw")
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
