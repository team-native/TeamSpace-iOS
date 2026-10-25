import Foundation

final class WorkspaceRepositoryImpl: WorkspaceRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchHome() async throws -> WorkspaceHome {
        try await request(Endpoint(method: .get, path: "workspace/home"), as: WorkspaceHomeResponseDTO.self).toEntity()
    }

    func fetchJoinedProjects() async throws -> [JoinedProject] {
        try await request(Endpoint(method: .get, path: "workspace/projects"), as: JoinedProjectListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func fetchMyDocuments() async throws -> [MyDocument] {
        try await request(Endpoint(method: .get, path: "workspace/documents"), as: MyDocumentListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func deleteDraft(documentId: Int) async throws {
        do {
            _ = try await client.request(Endpoint(method: .delete, path: "documents/\(documentId)"), as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    func fetchTodos() async throws -> [TodoItem] {
        try await request(Endpoint(method: .get, path: "workspace/todos"), as: TodoListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func addTodo(_ draft: TodoDraft) async throws -> TodoItem {
        let endpoint = Endpoint(method: .post, path: "workspace/todos", body: TodoCreateRequestDTO(draft))
        return try await request(endpoint, as: TodoDTO.self).toEntity()
    }

    func updateTodo(id: Int, status: TodoStatus) async throws -> TodoItem {
        let endpoint = Endpoint(
            method: .patch,
            path: "workspace/todos/\(id)",
            body: TodoUpdateRequestDTO(status: status.rawValue)
        )
        return try await request(endpoint, as: TodoDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
