import Foundation

/// 06-1 문서함 — 최근 수정한 문서가 위로 오도록 정렬합니다.
struct FetchLibraryUseCase {
    private let libraryRepository: LibraryRepository

    init(libraryRepository: LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    func execute() async throws -> LibraryOverview {
        let library = try await libraryRepository.fetchLibrary()
        return LibraryOverview(
            documents: library.documents.sorted { $0.updatedAt > $1.updatedAt },
            latestRevision: library.latestRevision
        )
    }
}
