import Foundation

/// 07-2 할 일 목록 — 마감이 가까운 순
struct FetchTodosUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> [TodoItem] {
        try await workspaceRepository.fetchTodos().sorted { $0.dueAt < $1.dueAt }
    }
}
