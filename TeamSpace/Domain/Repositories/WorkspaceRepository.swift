import Foundation

/// 내 공간 저장소
/// 명세서에는 `GET /workspace/todos` 만 있어 대시보드 요약 경로는 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol WorkspaceRepository: Sendable {
    /// GET /workspace/home — 07-1 내 공간 대시보드 요약
    func fetchHome() async throws -> WorkspaceHome
    /// GET /workspace/projects — 07-6 참여 프로젝트 (명세서에 없음)
    func fetchJoinedProjects() async throws -> [JoinedProject]
    /// GET /workspace/documents — 07-4 · 07-5 내가 작성 · 제출한 문서 (명세서에 없음)
    func fetchMyDocuments() async throws -> [MyDocument]
    /// DELETE /documents/{documentId} — 임시 저장 문서 삭제 (명세서에 없음)
    func deleteDraft(documentId: Int) async throws
    /// GET /workspace/todos — 사용자 할 일 목록 (명세서)
    func fetchTodos() async throws -> [TodoItem]
    /// POST /workspace/todos — 할 일 추가 (명세서에 없음)
    func addTodo(_ draft: TodoDraft) async throws -> TodoItem
    /// PATCH /workspace/todos/{todoId} — 완료 · 되돌리기 (명세서에 없음)
    func updateTodo(id: Int, status: TodoStatus) async throws -> TodoItem
}
