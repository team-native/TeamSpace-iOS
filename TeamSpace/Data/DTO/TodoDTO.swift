import Foundation

/// 목 서버(MockTodoStore)가 기억하는 할 일 모양 — 응답은 서버 형식(ServerTodoDTO)으로 바꿔 내보내요.

struct TodoDTO: Codable {
    let id: Int
    let title: String
    let dueAt: Date
    let hasTime: Bool
    let endsAt: Date?
    let place: String?
    let projectName: String?
    let linkKind: TodoLinkKind
    let linkedId: Int?
    let status: TodoStatus
    let completedAt: Date?

    func toEntity() -> TodoItem {
        TodoItem(
            id: id,
            title: title,
            dueAt: dueAt,
            hasTime: hasTime,
            endsAt: endsAt,
            place: place,
            projectName: projectName,
            linkKind: linkKind,
            linkedId: linkedId,
            status: status,
            completedAt: completedAt
        )
    }
}
