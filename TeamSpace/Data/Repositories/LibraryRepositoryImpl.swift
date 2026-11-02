import Foundation

final class LibraryRepositoryImpl: LibraryRepository, @unchecked Sendable {
    private let loader: DocPageLoader

    init(client: APIClient) {
        self.loader = DocPageLoader(client: client)
    }

    /// 최근 개정 배너는 `revised` 인 규칙 · 재무 문서 중 가장 최근 것이에요.
    func fetchLibrary() async throws -> LibraryOverview {
        let docs = try await loader.fetchDocs()
        let latest = docs
            .filter { $0.revised && $0.isRule }
            .max { $0.updatedAt < $1.updatedAt }
        return LibraryOverview(
            documents: docs.map { $0.toLibraryDocument() },
            latestRevision: latest.map { LibraryRevision(documentId: $0.slug, title: $0.title, effectiveAt: $0.effectiveAt) }
        )
    }

    func searchLibrary(keyword: String) async throws -> [LibraryDocument] {
        let docs = try await loader.fetchDocs(query: [URLQueryItem(name: "q", value: keyword)])
        return docs
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { $0.toLibraryDocument(excerpt: $0.copy) }
    }

    func fetchTemplate(id: String) async throws -> LibraryTemplate {
        let doc: ServerDocDTO
        do {
            doc = try await loader.request(Endpoint(method: .get, path: DocPageLoader.path(id)), as: ServerDocDTO.self)
        } catch AppError.notFound {
            throw AppError.notFound("템플릿을 찾을 수 없어요")
        }
        guard doc.libraryCategory == .template else { throw AppError.notFound("템플릿을 찾을 수 없어요") }
        return doc.toTemplate()
    }
}
