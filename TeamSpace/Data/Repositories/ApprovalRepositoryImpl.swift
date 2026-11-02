import Foundation

final class ApprovalRepositoryImpl: ApprovalRepository, @unchecked Sendable {
    private let client: APIClient

    private let lock = NSLock()
    private var viewerId: Int?

    init(client: APIClient) {
        self.client = client
    }

    func fetchMyApprovals() async throws -> [ApprovalItem] {
        try await fetchAll(box: "mine").map { $0.toItem() }
    }

    /// 받은 결재 = 지금 · 다음 차례(received) + 내가 처리한 것(handled).
    /// handled 에는 내 기안도 들어와서 내가 올린 결재는 빼고, 취소된 결재도 빼요.
    func fetchReceivedApprovals() async throws -> [ApprovalItem] {
        async let viewer = currentUserId()
        async let waiting = fetchAll(box: "received")
        async let handled = fetchAll(box: "handled")
        let me = try await viewer
        var seen = Set<Int>()
        return try await (waiting + handled)
            .filter { $0.authorId != me && seen.insert($0.id).inserted }
            .map { $0.toItem() }
            .filter { $0.status != .cancelled }
    }

    func fetchDetail(documentId: Int) async throws -> ApprovalDetail {
        async let viewer = currentUserId()
        let record = try await request(Endpoint(method: .get, path: "approvals/\(documentId)"), as: ServerApprovalDTO.self)
        return record.toDetail(viewerId: try await viewer)
    }

    /// 서버 승인은 의견을 받지 않아서, 의견이 있으면 처리 후 의견으로 남겨요.
    func decide(documentId: Int, decision: ApprovalDecision, comment: String?) async throws -> ApprovalDecisionResult {
        let endpoint: Endpoint
        switch decision {
        case .approve:
            endpoint = Endpoint(method: .post, path: "approvals/\(documentId)/approve")
        case .reject:
            endpoint = Endpoint(
                method: .post,
                path: "approvals/\(documentId)/reject",
                body: ServerApprovalRejectRequestDTO(reason: comment ?? "")
            )
        }
        let result = try await request(endpoint, as: ServerApprovalDecisionDTO.self)
        if decision == .approve, let comment, !comment.isEmpty {
            _ = try await addComment(documentId: documentId, body: comment)
        }
        return ApprovalDecisionResult(status: ApprovalStatus(serverValue: result.status), nextApproverName: nil)
    }

    func addComment(documentId: Int, body: String) async throws -> ApprovalComment {
        let endpoint = Endpoint(
            method: .post,
            path: "approvals/\(documentId)/comments",
            body: ServerApprovalCommentRequestDTO(text: body)
        )
        let comment = try await request(endpoint, as: ServerApprovalDTO.Comment.self)
        return ApprovalComment(id: 0, authorName: comment.who, body: comment.text, createdAt: comment.createdAt ?? Date())
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
        _ = try await request(Endpoint(method: .post, path: "approvals/\(documentId)/cancel"), as: IgnoredJSONValue.self)
    }

    /// 커서로 끝까지 (100건씩, 최대 5페이지)
    private func fetchAll(box: String) async throws -> [ServerApprovalDTO] {
        var items: [ServerApprovalDTO] = []
        var cursor: String?
        for _ in 0..<5 {
            var query = [URLQueryItem(name: "box", value: box), URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "approvals", queryItems: query), as: CursorPageDTO<ServerApprovalDTO>.self)
            items += page.items
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items
    }

    /// 내 id — 한 번 불러오면 기억해요.
    private func currentUserId() async throws -> Int {
        lock.lock()
        let cached = viewerId
        lock.unlock()
        if let cached { return cached }
        let id = try await request(Endpoint(method: .get, path: "me"), as: ServerMeIdDTO.self).id
        lock.lock()
        viewerId = id
        lock.unlock()
        return id
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
