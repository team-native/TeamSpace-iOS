import Foundation

/// 07-2 할 일 완료 · 되돌리기 — To-do 만 바뀌고 연결된 결재는 승인하지 않아요.
struct ToggleTodoUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(_ todo: TodoItem) async throws -> TodoItem {
        let next: TodoStatus = todo.status == .done ? .open : .done
        // 받은 결재 할 일(음수 id)은 서버가 결재에서 만들어 준 것이라 저장할 곳이 없어요. 화면에서만 체크해요.
        guard todo.id > 0 else {
            var updated = todo
            updated.status = next
            updated.completedAt = next == .done ? Date() : nil
            return updated
        }
        return try await workspaceRepository.updateTodo(id: todo.id, status: next)
    }
}
