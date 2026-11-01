import Foundation

final class SearchRepositoryImpl: SearchRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func search(query: String) async throws -> SearchResult {
        let endpoint = Endpoint(
            method: .get,
            path: "search",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "type", value: "ALL")
            ]
        )
        do {
            return try await client.request(endpoint, as: SearchResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
