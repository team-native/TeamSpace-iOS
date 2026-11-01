import Foundation

final class SearchRepositoryImpl: SearchRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func search(query: String, cursor: String?, limit: Int) async throws -> SearchResult {
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: "ALL"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        let endpoint = Endpoint(method: .get, path: "search", queryItems: queryItems)
        do {
            return try await client.request(endpoint, as: SearchResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
