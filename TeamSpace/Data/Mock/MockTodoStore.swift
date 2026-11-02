import Foundation

/// Mock 할 일 — Figma 07-2 나의 To-do 예시. 추가 · 완료를 메모리에 기억해요.
/// 결재 할 일의 linkedId(11)는 MockApprovalStore 의 받은 결재와 같아요.
final class MockTodoStore: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [TodoDTO]
    private var nextId = 100

    init(now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        func at(days: Int, hour: Double) -> Date {
            (calendar.date(byAdding: .day, value: days, to: today) ?? today).addingTimeInterval(hour * 3_600)
        }
        storage = [
            TodoDTO(id: 1, title: "QA 체크리스트 정리", dueAt: at(days: 0, hour: 18), hasTime: true, endsAt: nil,
                    place: nil, projectName: "Book-on", linkKind: .checklist, linkedId: 1, status: .open, completedAt: nil),
            TodoDTO(id: 2, title: "인원 지원 요청 검토", dueAt: at(days: 0, hour: 9), hasTime: false, endsAt: nil,
                    place: nil, projectName: "Book-on", linkKind: .approval, linkedId: 11, status: .open, completedAt: nil),
            TodoDTO(id: 3, title: "Book-on QA 점검 참여", dueAt: at(days: 7, hour: 15), hasTime: true, endsAt: at(days: 7, hour: 16),
                    place: "온라인", projectName: "Book-on", linkKind: .schedule, linkedId: 1, status: .open, completedAt: nil),
            TodoDTO(id: 4, title: "디자인 리뷰 자료 공유", dueAt: at(days: 0, hour: 9.5), hasTime: true, endsAt: nil,
                    place: nil, projectName: "Book-on", linkKind: .manual, linkedId: nil, status: .done,
                    completedAt: at(days: 0, hour: 9.5))
        ]
    }

    /// GET /todos — 서버 형식 `{items, nextCursor}`, 오프셋 커서. 결재 할 일은 `approval:{결재 id}`
    func listJSON(cursor: String? = nil, limit: Int = 30) -> String {
        lock.lock()
        defer { lock.unlock() }
        let start = Int(cursor ?? "0") ?? 0
        let page = Array(storage.dropFirst(start).prefix(limit))
        let next: Any = start + limit < storage.count ? String(start + limit) : NSNull()
        return json(["items": page.map(Self.serverFields), "nextCursor": next])
    }

    /// POST /todos — 날짜만 정한 할 일로 추가해요.
    func add(_ request: ServerTodoCreateRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        nextId += 1
        let dueAt = ServerTodoDTO.date(fromDay: request.dueDate) ?? Date()
        let item = TodoDTO(
            id: nextId, title: request.title, dueAt: dueAt, hasTime: false, endsAt: nil, place: nil,
            projectName: request.projectName, linkKind: TodoLinkKind(serverCategory: request.category),
            linkedId: nil, status: .open, completedAt: nil
        )
        storage.append(item)
        return json(Self.serverFields(item))
    }

    /// PATCH /todos/{id} — 결재 할 일(`approval:`)은 서버처럼 찾을 수 없어요.
    func update(id: Int, status: String, now: Date = Date()) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id && $0.linkKind != .approval }) else { return nil }
        let old = storage[index]
        let newStatus: TodoStatus = status == "완료" ? .done : .open
        let item = TodoDTO(
            id: old.id, title: old.title, dueAt: old.dueAt, hasTime: old.hasTime, endsAt: old.endsAt,
            place: old.place, projectName: old.projectName, linkKind: old.linkKind, linkedId: old.linkedId,
            status: newStatus, completedAt: newStatus == .done ? now : nil
        )
        storage[index] = item
        return json(Self.serverFields(item))
    }

    private static func serverFields(_ item: TodoDTO) -> [String: Any] {
        var fields: [String: Any] = [:]
        let isApproval = item.linkKind == .approval
        fields["id"] = isApproval ? "\(ServerTodoDTO.approvalPrefix)\(item.linkedId ?? item.id)" : String(item.id)
        fields["title"] = item.title
        fields["dueDate"] = PostListQuery.day(item.dueAt)
        if item.hasTime { fields["dueAt"] = MockBoardStore.pythonISO(item.dueAt) }
        fields["projectName"] = item.projectName ?? ""
        fields["category"] = item.linkKind.serverCategory
        fields["status"] = item.status == .done ? "완료" : "미완료"
        fields["completedAt"] = item.completedAt.map(MockBoardStore.pythonISO) ?? NSNull()
        fields["createdAt"] = MockBoardStore.pythonISO(item.dueAt)
        if isApproval {
            fields["sourceType"] = "approval"
            fields["sourceId"] = String(item.linkedId ?? item.id)
        }
        return fields
    }

    /// 07-1 대시보드의 To-do 요약 — 오늘까지 남은 할 일 · 오늘 완료한 할 일
    func summary(now: Date = Date(), calendar: Calendar = .current) -> (today: [String], completed: Int) {
        lock.lock()
        defer { lock.unlock() }
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let today = storage.filter { $0.status == .open && $0.dueAt < endOfToday }.sorted { $0.dueAt < $1.dueAt }
        let completed = storage.filter { item in
            guard item.status == .done, let completedAt = item.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: now)
        }
        return (today.map(\.title), completed.count)
    }

    private func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}
