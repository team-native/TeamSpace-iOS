import Foundation

/// 할 일 상태
enum TodoStatus: String, UnknownCaseDecodable, Encodable, Hashable, Sendable {
    case open = "OPEN"
    case done = "DONE"
    case unknown = "UNKNOWN"

    static let unknownCase: TodoStatus = .unknown
}

/// 할 일이 연결된 업무
enum TodoLinkKind: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case checklist = "CHECKLIST"   // 프로젝트 체크리스트
    case approval = "APPROVAL"     // 받은 결재
    case schedule = "SCHEDULE"     // 일정
    case manual = "MANUAL"         // 연결 없이 직접 만든 할 일
    case unknown = "UNKNOWN"

    static let unknownCase: TodoLinkKind = .unknown
}

/// 07-2 나의 To-do 한 건
/// 할 일을 완료해도 연결된 결재 · 일정은 바뀌지 않아요. (알림 읽음 · 할 일 완료 · 결재 승인은 각각 다른 상태)
struct TodoItem: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let dueAt: Date
    /// 시간까지 정해진 할 일인지 ("오늘 18:00" / "오늘")
    let hasTime: Bool
    /// 일정 연결일 때 끝나는 시간
    let endsAt: Date?
    let place: String?
    let projectName: String?
    let linkKind: TodoLinkKind
    /// 연결된 결재 문서 · 일정 · 체크리스트 ID
    let linkedId: Int?
    var status: TodoStatus
    var completedAt: Date?
}

/// 할 일 추가 (07-2 빠르게 추가)
struct TodoDraft: Equatable, Sendable {
    let title: String
    let dueAt: Date
    let projectName: String?
    let linkKind: TodoLinkKind
}
