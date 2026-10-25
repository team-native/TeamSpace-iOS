import Foundation

/// 07-2 빠르게 추가
struct AddTodoUseCase {
    static let titleLimit = 40

    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    /// 입력이 올바르지 않으면 안내 문구, 괜찮으면 nil
    static func validationMessage(title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "할 일 제목을 입력해 주세요." }
        if trimmed.count > titleLimit { return "제목은 \(titleLimit)자까지 쓸 수 있어요." }
        return nil
    }

    func execute(_ draft: TodoDraft) async throws -> TodoItem {
        if let message = Self.validationMessage(title: draft.title) {
            throw AppError.invalidInput(message)
        }
        let trimmed = TodoDraft(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueAt: draft.dueAt,
            projectName: draft.projectName,
            linkKind: draft.linkKind
        )
        return try await workspaceRepository.addTodo(trimmed)
    }
}
