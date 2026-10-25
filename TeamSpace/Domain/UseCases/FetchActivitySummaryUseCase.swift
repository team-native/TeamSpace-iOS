import Foundation

/// 07-12 내 활동 요약
struct FetchActivitySummaryUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> ActivitySummary {
        try await workspaceRepository.fetchActivitySummary()
    }
}
