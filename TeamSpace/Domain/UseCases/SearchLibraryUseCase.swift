import Foundation

/// 06-2 문서 검색 — 앞뒤 공백을 빼고, 빈 검색어는 서버에 묻지 않아요.
struct SearchLibraryUseCase {
    private let libraryRepository: LibraryRepository

    init(libraryRepository: LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    func execute(keyword: String) async throws -> [LibraryDocument] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await libraryRepository.searchLibrary(keyword: trimmed)
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
