import Foundation

struct FetchLibraryTemplateUseCase {
    private let libraryRepository: LibraryRepository

    init(libraryRepository: LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    func execute(id: String) async throws -> LibraryTemplate {
        try await libraryRepository.fetchTemplate(id: id)
    }
}
