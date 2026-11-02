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

    func fetchSchedules(month: Date) async throws -> [ScheduleEvent] {
        let endpoint = Endpoint(
            method: .get,
            path: "workspace/schedules",
            queryItems: [URLQueryItem(name: "month", value: FinanceMonthParameter.string(from: month))]
        )
        return try await request(endpoint, as: ScheduleListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchScheduleDetail(id: Int) async throws -> ScheduleEventDetail {
        try await request(Endpoint(method: .get, path: "workspace/schedules/\(id)"), as: ScheduleDetailDTO.self).toEntity()
    }

    func respond(scheduleId: Int, response: ScheduleResponse) async throws -> ScheduleEvent {
        let endpoint = Endpoint(
            method: .post,
            path: "workspace/schedules/\(scheduleId)/response",
            body: ScheduleResponseRequestDTO(response: response.rawValue)
        )
        return try await request(endpoint, as: ScheduleEventDTO.self).toEntity()
    }

    func updateReminders(scheduleId: Int, reminders: [ReminderTiming]) async throws -> [ReminderTiming] {
        let endpoint = Endpoint(
            method: .patch,
            path: "workspace/schedules/\(scheduleId)/reminders",
            body: ScheduleRemindersDTO(reminders: reminders.map(\.rawValue))
        )
        return try await request(endpoint, as: ScheduleRemindersDTO.self).reminders.compactMap(ReminderTiming.init(rawValue:))
    }

    func fetchActivitySummary() async throws -> ActivitySummary {
        try await request(Endpoint(method: .get, path: "workspace/activity"), as: ActivitySummaryDTO.self).toEntity()
    }

    func fetchMyPosts() async throws -> MyPosts {
        try await request(Endpoint(method: .get, path: "workspace/posts"), as: MyPostsResponseDTO.self).toEntity()
    }

    func fetchMyProposals() async throws -> [MyProposal] {
        try await request(Endpoint(method: .get, path: "workspace/proposals"), as: MyProposalListResponseDTO.self).toEntity()
    }

    func fetchProfile() async throws -> MyProfile {
        try await request(Endpoint(method: .get, path: "workspace/profile"), as: MyProfileDTO.self).toEntity()
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> MyProfile {
        let endpoint = Endpoint(method: .patch, path: "workspace/profile", body: ProfileUpdateRequestDTO(update))
        return try await request(endpoint, as: MyProfileDTO.self).toEntity()
    }

    /// GET /todos — 오프셋 커서로 끝까지 (100건씩, 최대 5페이지)
    func fetchTodos() async throws -> [TodoItem] {
        var items: [TodoItem] = []
        var cursor: String?
        for _ in 0..<5 {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "todos", queryItems: query), as: CursorPageDTO<ServerTodoDTO>.self)
            items += page.items.compactMap { $0.toEntity() }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items
    }

    func addTodo(_ draft: TodoDraft) async throws -> TodoItem {
        let endpoint = Endpoint(method: .post, path: "todos", body: ServerTodoCreateRequestDTO(draft))
        guard let item = try await request(endpoint, as: ServerTodoDTO.self).toEntity() else {
            throw AppError.unknown("할 일 번호를 읽지 못했어요.")
        }
        return item
    }

    func updateTodo(id: Int, status: TodoStatus) async throws -> TodoItem {
        let endpoint = Endpoint(method: .patch, path: "todos/\(id)", body: ServerTodoPatchRequestDTO(status: status.serverValue))
        guard let item = try await request(endpoint, as: ServerTodoDTO.self).toEntity() else {
            throw AppError.unknown("할 일 번호를 읽지 못했어요.")
        }
        return item
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
