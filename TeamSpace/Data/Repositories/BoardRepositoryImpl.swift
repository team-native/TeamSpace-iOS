import Foundation

final class BoardRepositoryImpl: BoardRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchBoard() async throws -> Board {
        try await request(Endpoint(method: .get, path: "posts"), as: BoardResponseDTO.self).toEntity()
    }

    func search(keyword: String) async throws -> BoardSearchResult {
        let endpoint = Endpoint(
            method: .get,
            path: "posts/search",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
        return try await request(endpoint, as: BoardSearchResponseDTO.self).toEntity()
    }

    func fetchPost(id: Int) async throws -> PostDetail {
        try await request(Endpoint(method: .get, path: "posts/\(id)"), as: PostDetailDTO.self).toEntity()
    }

    func toggleLike(postId: Int) async throws -> PostLike {
        let dto = try await request(Endpoint(method: .post, path: "posts/\(postId)/like"), as: PostLikeResponseDTO.self)
        return PostLike(isLiked: dto.isLiked, likeCount: dto.likeCount)
    }

    func report(postId: Int, reason: PostReportReason) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "posts/\(postId)/reports",
            body: PostReportRequestDTO(reason: reason.rawValue)
        )
        try await send(endpoint)
    }

    func deletePost(id: Int) async throws {
        try await send(Endpoint(method: .delete, path: "posts/\(id)"))
    }

    /// 응답 본문이 없어도 되는 요청
    private func send(_ endpoint: Endpoint) async throws {
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
