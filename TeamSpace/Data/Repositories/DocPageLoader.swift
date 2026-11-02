import Foundation

/// GET /docs 를 끝까지 (100건씩, 최대 5페이지)
struct DocPageLoader {
    let client: APIClient

    func fetchDocs(query: [URLQueryItem] = []) async throws -> [ServerDocDTO] {
        var docs: [ServerDocDTO] = []
        var cursor: String?
        for _ in 0..<5 {
            var items = query + [URLQueryItem(name: "limit", value: "100")]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "docs", queryItems: items), as: CursorPageDTO<ServerDocDTO>.self)
            docs += page.items
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return docs
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    /// slug 에 `/` 같은 글자가 있어도 경로 한 칸으로 보내요.
    static func path(_ slug: String, _ suffix: String? = nil) -> String {
        let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? slug
        return ["docs", encoded, suffix].compactMap { $0 }.joined(separator: "/")
    }
}
