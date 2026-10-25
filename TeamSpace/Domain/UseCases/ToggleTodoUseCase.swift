import Foundation

/// 07-2 할 일 완료 · 되돌리기 — To-do 만 바뀌고 연결된 결재는 승인하지 않아요.
struct ToggleTodoUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(_ todo: TodoItem) async throws -> TodoItem {
        let next: TodoStatus = todo.status == .done ? .open : .done
        return try await workspaceRepository.updateTodo(id: todo.id, status: next)
    }
}
