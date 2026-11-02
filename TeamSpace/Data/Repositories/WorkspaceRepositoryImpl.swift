import Foundation

final class WorkspaceRepositoryImpl: WorkspaceRepository, @unchecked Sendable {
    private let client: APIClient
    private let reminderStore: ScheduleReminderStore
    /// 일정 상세 · 참석 응답은 서버에 단건 경로가 없어 마지막으로 불러온 월별 일정에서 찾아요.
    private let lock = NSLock()
    private var eventCache: [Int: ServerEventDTO] = [:]

    init(client: APIClient, reminderStore: ScheduleReminderStore = ScheduleReminderStore()) {
        self.client = client
        self.reminderStore = reminderStore
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

    /// GET /events?month=YYYY-MM
    func fetchSchedules(month: Date) async throws -> [ScheduleEvent] {
        try await fetchEvents(month: month).compactMap { $0.toEntity() }
    }

    /// 서버에 일정 상세 경로가 없어 이번 달 ± 2달 안에서 찾아요.
    func fetchScheduleDetail(id: Int) async throws -> ScheduleEventDetail {
        guard let event = try await findEvent(id: id), let detail = event.toDetail(reminders: reminderStore.reminders(for: id)) else {
            throw AppError.notFound("일정을 찾을 수 없어요.")
        }
        return detail
    }

    /// POST /events/{id}/rsvp — 응답은 `{eventId, rsvp}` 뿐이라 불러온 일정에 응답을 붙여 돌려줘요.
    func respond(scheduleId: Int, response: ScheduleResponse) async throws -> ScheduleEvent {
        let endpoint = Endpoint(
            method: .post,
            path: "events/\(scheduleId)/rsvp",
            body: ServerRsvpRequestDTO(rsvp: response.serverValue)
        )
        _ = try await request(endpoint, as: IgnoredJSONValue.self)
        guard var event = try await findEvent(id: scheduleId)?.toEntity() else {
            throw AppError.notFound("일정을 찾을 수 없어요.")
        }
        event.myResponse = response
        event.respondedAt = Date()
        return event
    }

    /// 서버에 리마인더가 없어 기기에 저장해요.
    func updateReminders(scheduleId: Int, reminders: [ReminderTiming]) async throws -> [ReminderTiming] {
        reminderStore.save(reminders, for: scheduleId)
        return reminderStore.reminders(for: scheduleId)
    }

    private func fetchEvents(month: Date) async throws -> [ServerEventDTO] {
        let query = [URLQueryItem(name: "month", value: FinanceMonthParameter.string(from: month)), URLQueryItem(name: "limit", value: "200")]
        let items = try await request(Endpoint(method: .get, path: "events", queryItems: query), as: CursorPageDTO<ServerEventDTO>.self).items
        lock.lock()
        for item in items { eventCache[item.id] = item }
        lock.unlock()
        return items
    }

    /// 캐시에 있으면 그 달을 다시 불러 최신 응답을 읽고, 없으면 이번 달부터 앞뒤로 찾아요.
    private func findEvent(id: Int) async throws -> ServerEventDTO? {
        lock.lock()
        let cached = eventCache[id]
        lock.unlock()
        let calendar = Calendar(identifier: .gregorian)
        var months: [Date] = []
        if let day = cached.flatMap({ ServerTodoDTO.date(fromDay: $0.date) }) { months.append(day) }
        let now = Date()
        months += [0, -1, 1, -2, 2].compactMap { calendar.date(byAdding: .month, value: $0, to: now) }
        for month in months {
            if let found = try await fetchEvents(month: month).first(where: { $0.id == id }) { return found }
        }
        return nil
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
