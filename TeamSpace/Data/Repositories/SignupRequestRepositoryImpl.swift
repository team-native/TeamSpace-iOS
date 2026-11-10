import Foundation

final class SignupRequestRepositoryImpl: SignupRequestRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchSignupRequests(cursor: String?, limit: Int) async throws -> CursorPage<SignupRequestItem> {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        let page = try await request(
            Endpoint(method: .get, path: "admin/signup-requests", queryItems: query),
            as: CursorPageDTO<ServerSignupRequestDTO>.self
        )
        return CursorPage(items: page.items.map { $0.toEntity() }, nextCursor: page.nextCursor)
    }

    /// 응답 `{userId, memberId, status: "APPROVED"}` 은 쓰지 않아요.
    func approve(id: Int, temporaryPassword: String?, memberId: String?) async throws {
        let body = ServerSignupApproveRequestDTO(temporaryPassword: temporaryPassword, memberId: memberId)
        _ = try await request(
            Endpoint(method: .post, path: "admin/signup-requests/\(id)/approve", body: body),
            as: EmptyResponseDTO.self
        )
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
