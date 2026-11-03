import Foundation

final class WorkspaceRepositoryImpl: WorkspaceRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 07-1 — 서버에 홈 전용 응답이 없어 여러 API 를 함께 불러요.
    /// 요약(/me/summary) · 내 정보(/me)만 필수고, 나머지는 실패하면 그 카드만 비워요.
    func fetchHome() async throws -> WorkspaceHome {
        async let summary = request(Endpoint(method: .get, path: "me/summary"), as: ServerMeSummaryDTO.self)
        async let me = request(Endpoint(method: .get, path: "me"), as: ServerProfileDTO.self)
        async let todos = try? fetchTodos()
        async let notification = try? request(
            Endpoint(method: .get, path: "notifications", queryItems: [URLQueryItem(name: "unread", value: "true"), URLQueryItem(name: "limit", value: "1")]),
            as: CursorPageDTO<ServerNotificationPreviewDTO>.self
        ).items.first
        async let received = try? approvals(box: "received")
        async let mine = try? approvals(box: "mine")
        async let projects = try? fetchJoinedProjectRecords()
        async let schedules = try? upcomingSchedules()
        async let records = homeRecords()

        let (summaryValue, meValue) = try await (summary, me)
        let todayTitles = (await todos ?? []).filter { item in
            item.status != .done && Calendar.current.isDateInToday(item.dueAt)
        }.map(\.title)
        let waiting = (await received ?? [])
            .filter { $0.authorId != meValue.id && ApprovalStatus(serverValue: $0.status).isWaiting }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        let submitted = (await mine ?? [])
            .compactMap { $0.toMyDocument() }
            .filter { $0.status != .draft && $0.status != .cancelled }
            .max { $0.updatedAt < $1.updatedAt }
        let preview = await notification
        let recordsValue = await records

        return WorkspaceHome(
            affiliation: meValue.dept.isEmpty ? "Native" : "Native / \(meValue.dept)",
            todo: WorkspaceTodoSummary(
                todayCount: summaryValue.todos.today,
                completedCount: summaryValue.todos.completed,
                todayTitles: todayTitles
            ),
            notification: preview.map {
                WorkspaceNotificationPreview(
                    unreadCount: summaryValue.unreadNotifications,
                    title: $0.title,
                    subtitle: [$0.kind, $0.createdAt.map { "\(TSFormat.shortDate($0)) \(TSFormat.time($0))" } ?? ""]
                        .filter { !$0.isEmpty }.joined(separator: " · ")
                )
            },
            receivedApproval: waiting.first.map {
                WorkspaceApprovalPreview(
                    documentId: $0.id, waitingCount: waiting.count, title: $0.title,
                    requesterName: $0.author, requestedAt: $0.date ?? Date()
                )
            },
            submittedDocument: submitted.map {
                WorkspaceSubmittedDocument(
                    documentId: $0.id, title: $0.title, amount: $0.amount, submittedAt: $0.submittedAt ?? $0.updatedAt,
                    status: $0.status, currentApproverName: $0.currentApprover?.name
                )
            },
            projects: (await projects ?? []).map { $0.toWorkspaceProject() },
            schedules: await schedules ?? [],
            records: WorkspaceRecords(
                latestPost: recordsValue.post,
                proposalCount: summaryValue.myProposals,
                latestProposal: recordsValue.proposal,
                inquiries: recordsValue.inquiries
            )
        )
    }

    /// GET /approvals?box= 첫 페이지 (홈은 최근 것만 봐요)
    private func approvals(box: String) async throws -> [ServerApprovalDTO] {
        let query = [URLQueryItem(name: "box", value: box), URLQueryItem(name: "limit", value: "50")]
        return try await request(Endpoint(method: .get, path: "approvals", queryItems: query), as: CursorPageDTO<ServerApprovalDTO>.self).items
    }

    private func fetchJoinedProjectRecords() async throws -> [ServerJoinedProjectDTO] {
        try await request(Endpoint(method: .get, path: "me/projects"), as: CursorPageDTO<ServerJoinedProjectDTO>.self).items
    }

    /// 이번 달 · 다음 달 일정 중 지금 이후에 시작하는 것
    private func upcomingSchedules(now: Date = Date()) async throws -> [WorkspaceSchedule] {
        let next = Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: now) ?? now
        async let this = fetchEvents(month: now)
        async let following = fetchEvents(month: next)
        var seen = Set<Int>()
        return try await (this + following)
            .compactMap { $0.toWorkspaceSchedule() }
            .filter { $0.startsAt >= now && seen.insert($0.id).inserted }
            .sorted { $0.startsAt < $1.startsAt }
    }

    /// 내가 남긴 기록 — 최근 글(/posts?mine=true) · 최근 제안(/proposals 중 내 것) · 최근 문의 2건(/inquiries)
    private func homeRecords() async -> (post: WorkspacePostPreview?, proposal: WorkspaceProposalPreview?, inquiries: [WorkspaceInquiryPreview]) {
        async let posts = try? request(
            Endpoint(method: .get, path: "posts", queryItems: [URLQueryItem(name: "mine", value: "true"), URLQueryItem(name: "limit", value: "1")]),
            as: CursorPageDTO<ServerPostItemDTO>.self
        ).items
        async let proposals = try? request(
            Endpoint(method: .get, path: "proposals", queryItems: [URLQueryItem(name: "limit", value: "100")]),
            as: CursorPageDTO<ServerProposalDTO>.self
        ).items
        async let inquiries = try? request(
            Endpoint(method: .get, path: "inquiries", queryItems: [URLQueryItem(name: "limit", value: "2")]),
            as: CursorPageDTO<ServerInquiryDTO>.self
        ).items
        let post = await posts?.first.map { WorkspacePostPreview(title: $0.title, createdAt: $0.createdAt) }
        let proposal = await proposals?.map { $0.toEntity() }.first { $0.isMine }.map {
            WorkspaceProposalPreview(title: $0.title, status: $0.status, recommendCount: $0.recommendCount)
        }
        let inquiryPreviews = (await inquiries ?? []).map { $0.toEntity() }.prefix(2).map {
            WorkspaceInquiryPreview(title: $0.title, status: $0.status)
        }
        return (post, proposal, Array(inquiryPreviews))
    }

    /// GET /me/projects — 서버가 한 번에 다 줘요 (`nextCursor` 는 항상 null)
    func fetchJoinedProjects() async throws -> [JoinedProject] {
        try await request(Endpoint(method: .get, path: "me/projects"), as: CursorPageDTO<ServerJoinedProjectDTO>.self)
            .items.map { $0.toEntity() }
    }

    /// GET /approvals?box=mine — 07-4 · 07-5 는 내가 올린 결재예요. 취소한 임시 저장(=삭제)은 빼요.
    func fetchMyDocuments() async throws -> [MyDocument] {
        var items: [ServerApprovalDTO] = []
        var cursor: String?
        for _ in 0..<5 {
            var query = [URLQueryItem(name: "box", value: "mine"), URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "approvals", queryItems: query), as: CursorPageDTO<ServerApprovalDTO>.self)
            items += page.items
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items.compactMap { $0.toMyDocument() }
    }

    /// 서버에 결재 삭제가 없어 작성 중인 결재를 취소해요. (POST /approvals/{id}/cancel)
    func deleteDraft(documentId: Int) async throws {
        _ = try await request(Endpoint(method: .post, path: "approvals/\(documentId)/cancel"), as: IgnoredJSONValue.self)
    }

    /// GET /events?month=YYYY-MM
    func fetchSchedules(month: Date) async throws -> [ScheduleEvent] {
        try await fetchEvents(month: month).compactMap { $0.toEntity() }
    }

    func createSchedule(_ draft: ScheduleDraft) async throws -> Int {
        let body = ServerEventCreateRequestDTO(draft)
        let created = try await request(Endpoint(method: .post, path: "admin/events", body: body), as: ServerIdResponseDTO.self)
        guard let id = Int(created.id) else { throw AppError.unknown("일정 번호를 읽지 못했어요.") }
        return id
    }

    /// GET /events/{id} + GET /events/{id}/reminders — 리마인더를 못 불러오면 꺼진 것으로 보여줘요.
    func fetchScheduleDetail(id: Int) async throws -> ScheduleEventDetail {
        async let remindersTask = fetchReminders(eventId: id)
        let event = try await fetchEvent(id: id)
        guard let detail = event.toDetail(reminders: await remindersTask) else {
            throw AppError.notFound("일정을 찾을 수 없어요.")
        }
        return detail
    }

    /// POST /events/{id}/rsvp — 응답은 `{eventId, rsvp}` 뿐이라 GET /events/{id} 로 다시 읽어요.
    func respond(scheduleId: Int, response: ScheduleResponse) async throws -> ScheduleEvent {
        let endpoint = Endpoint(
            method: .post,
            path: "events/\(scheduleId)/rsvp",
            body: ServerRsvpRequestDTO(rsvp: response.serverValue)
        )
        _ = try await request(endpoint, as: IgnoredJSONValue.self)
        guard var event = try await fetchEvent(id: scheduleId).toEntity() else {
            throw AppError.notFound("일정을 찾을 수 없어요.")
        }
        event.myResponse = response
        event.respondedAt = event.respondedAt ?? Date()
        return event
    }

    /// PATCH /events/{id}/reminders — 세 시점을 모두 보내요.
    func updateReminders(scheduleId: Int, reminders: [ReminderTiming]) async throws -> [ReminderTiming] {
        let endpoint = Endpoint(
            method: .patch,
            path: "events/\(scheduleId)/reminders",
            body: ServerEventRemindersDTO(reminders)
        )
        return try await request(endpoint, as: ServerEventRemindersDTO.self).reminders
    }

    private func fetchEvents(month: Date) async throws -> [ServerEventDTO] {
        let query = [URLQueryItem(name: "month", value: FinanceMonthParameter.string(from: month)), URLQueryItem(name: "limit", value: "200")]
        return try await request(Endpoint(method: .get, path: "events", queryItems: query), as: CursorPageDTO<ServerEventDTO>.self).items
    }

    private func fetchEvent(id: Int) async throws -> ServerEventDTO {
        try await request(Endpoint(method: .get, path: "events/\(id)"), as: ServerEventDTO.self)
    }

    private func fetchReminders(eventId: Int) async -> [ReminderTiming] {
        do {
            return try await request(Endpoint(method: .get, path: "events/\(eventId)/reminders"), as: ServerEventRemindersDTO.self).reminders
        } catch {
            AppLog.record(error, context: "schedule.reminders")
            return []
        }
    }

    /// GET /me/summary
    func fetchActivitySummary() async throws -> ActivitySummary {
        try await request(Endpoint(method: .get, path: "me/summary"), as: ServerMeSummaryDTO.self).toActivitySummary()
    }

    /// 내가 쓴 글 GET /posts?mine=true · 내가 쓴 댓글 GET /me/activity 중 comment
    func fetchMyPosts() async throws -> MyPosts {
        async let posts = fetchPages(path: "posts", query: [URLQueryItem(name: "mine", value: "true")], as: ServerPostItemDTO.self)
        async let activity = fetchPages(path: "me/activity", query: [], as: ServerActivityItemDTO.self)
        return try await MyPosts(
            posts: posts.map { $0.toMyPost() }.sorted { $0.createdAt > $1.createdAt },
            comments: activity.compactMap { $0.toComment() }.sorted { $0.createdAt > $1.createdAt }
        )
    }

    /// GET /proposals 중 내 것 — 서버에 내 제안만 보는 필터가 없어요.
    func fetchMyProposals() async throws -> [MyProposal] {
        try await fetchPages(path: "proposals", query: [], as: ServerProposalDTO.self)
            .filter(\.mine)
            .map { $0.toMyProposal() }
    }

    /// `{items, nextCursor}` 를 100건씩 끝까지 (최대 5페이지)
    private func fetchPages<Item: Decodable>(path: String, query: [URLQueryItem], as type: Item.Type) async throws -> [Item] {
        var items: [Item] = []
        var cursor: String?
        for _ in 0..<5 {
            var queryItems = query + [URLQueryItem(name: "limit", value: "100")]
            if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: path, queryItems: queryItems), as: CursorPageDTO<Item>.self)
            items += page.items
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items
    }

    func fetchProfile() async throws -> MyProfile {
        try await request(Endpoint(method: .get, path: "me"), as: ServerProfileDTO.self).toEntity()
    }

    func updateProfile(_ update: ProfileUpdate) async throws -> MyProfile {
        let endpoint = Endpoint(method: .patch, path: "me", body: ServerProfilePatchRequestDTO(update))
        return try await request(endpoint, as: ServerProfileDTO.self).toEntity()
    }

    func changePassword(current: String, new: String) async throws {
        let body = ServerPasswordChangeRequestDTO(currentPassword: current, newPassword: new)
        _ = try await request(Endpoint(method: .patch, path: "me/settings", body: body), as: IgnoredJSONValue.self)
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
