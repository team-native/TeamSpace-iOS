import Foundation

/// 일정 추가 — 서버 `scope` (팀 · 프로젝트 · 개인)
enum ScheduleScope: String, CaseIterable, Sendable {
    case team = "팀"
    case project = "프로젝트"
    case personal = "개인"
}

/// 일정 추가 입력 (POST /admin/events)
struct ScheduleDraft: Equatable, Sendable {
    static let titleLimit = 60
    static let agendaLimit = 1_000

    var title = ""
    var scope: ScheduleScope = .team
    /// 날짜 (시각은 무시해요)
    var date: Date
    var startsAt: Date
    var endsAt: Date
    var place = ""
    var agenda = ""
    /// 참석 확인 받기
    var asksRSVP = true

    /// 고른 날 오후 2시 ~ 3시로 시작해요.
    init(date: Date, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        self.date = day
        startsAt = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day) ?? day
        endsAt = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day) ?? day
    }
}
