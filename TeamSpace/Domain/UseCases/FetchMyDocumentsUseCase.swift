import Foundation

/// 07-4 · 07-5 내 문서 — 최근에 바뀐 문서가 위로
struct FetchMyDocumentsUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> [MyDocument] {
        try await workspaceRepository.fetchMyDocuments().sorted { $0.updatedAt > $1.updatedAt }
    }
}
