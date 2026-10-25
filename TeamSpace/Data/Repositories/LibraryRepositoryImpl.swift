import Foundation

final class LibraryRepositoryImpl: LibraryRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchLibrary() async throws -> LibraryOverview {
        try await request(Endpoint(method: .get, path: "library"), as: LibraryResponseDTO.self).toEntity()
    }

    func searchLibrary(keyword: String) async throws -> [LibraryDocument] {
        let endpoint = Endpoint(
            method: .get,
            path: "library/search",
            queryItems: [URLQueryItem(name: "keyword", value: keyword)]
        )
        return try await request(endpoint, as: LibrarySearchResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchTemplate(id: Int) async throws -> LibraryTemplate {
        try await request(
            Endpoint(method: .get, path: "library/templates/\(id)"),
            as: LibraryTemplateResponseDTO.self
        ).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
