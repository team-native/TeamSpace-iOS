import Foundation

/// 일정 참석 응답
enum ScheduleResponse: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case attend = "ATTEND"
    case decline = "DECLINE"
    case undecided = "UNDECIDED"
    case unknown = "UNKNOWN"

    static let unknownCase: ScheduleResponse = .unknown
    /// 화면에서 고를 수 있는 응답
    static let selectable: [ScheduleResponse] = [.attend, .decline, .undecided]
}

/// 일정 리마인더 시점
enum ReminderTiming: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case dayBefore = "DAY_BEFORE"
    case hourBefore = "HOUR_BEFORE"
    case tenMinutesBefore = "TEN_MINUTES_BEFORE"
    case unknown = "UNKNOWN"

    static let unknownCase: ReminderTiming = .unknown
    static let selectable: [ReminderTiming] = [.dayBefore, .hourBefore, .tenMinutesBefore]
}

/// 07-7 일정 · 07-9 일정 상세 시트 한 건
struct ScheduleEvent: Equatable, Identifiable, Sendable {
    let id: Int
    let scope: WorkspaceScheduleScope
    let title: String
    let startsAt: Date
    let endsAt: Date
    let place: String
    /// 예) "Discode", "4층 홈베이스"
    let placeDetail: String?
    let organizerName: String
    let participantCount: Int
    /// 등록 뒤에 시간 · 장소가 바뀌었는지
    let isChanged: Bool
    var myResponse: ScheduleResponse? = nil
    var respondedAt: Date? = nil
}

/// 07-8 전체 일정 상세 — 일정 + 모임 정보 · 안건 · 관련 문서 · 변경 이력 · 리마인더
struct ScheduleEventDetail: Equatable, Sendable {
    var event: ScheduleEvent
    /// 예) "정기 활동"
    let category: String
    let summary: String
    /// 주최 (예: NativeOps)
    let host: String
    /// 참석 대상
    let audience: String
    /// 진행 (예: 양지우 · NativeOps)
    let facilitator: String
    let agenda: [ScheduleAgendaItem]
    let agendaNote: String?
    let relatedDocument: ScheduleRelatedDocument?
    let history: [ScheduleChange]
    let historyNote: String?
    var reminders: [ReminderTiming]
}

struct ScheduleAgendaItem: Equatable, Sendable {
    let startsAt: Date
    let endsAt: Date
    let title: String
}

struct ScheduleRelatedDocument: Equatable, Sendable {
    let title: String
    let owner: String
    let updatedAt: Date
}

/// 변경 이력 한 줄 (최근 것이 위)
struct ScheduleChange: Equatable, Sendable {
    let title: String
    let changedAt: Date
    let detail: String
}
