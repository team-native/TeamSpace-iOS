import Foundation

/// GET /workspace/todos 응답의 `data`
/// 명세서에 응답 예시가 없어 Figma 07-2 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct TodoListResponseDTO: Decodable {
    let list: [TodoDTO]
}

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

/// POST /workspace/todos 요청 바디
struct TodoCreateRequestDTO: Codable {
    let title: String
    let dueAt: Date
    let projectName: String?
    let linkKind: String

    init(_ draft: TodoDraft) {
        title = draft.title
        dueAt = draft.dueAt
        projectName = draft.projectName
        linkKind = draft.linkKind.rawValue
    }
}

/// PATCH /workspace/todos/{todoId} 요청 바디
struct TodoUpdateRequestDTO: Codable {
    let status: String
}
