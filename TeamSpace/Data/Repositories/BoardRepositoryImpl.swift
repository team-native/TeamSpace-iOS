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

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
