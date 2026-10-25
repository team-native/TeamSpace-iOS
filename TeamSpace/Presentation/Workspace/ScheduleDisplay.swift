import SwiftUI

extension ScheduleEvent {
    /// "15:00 – 16:00"
    var timeText: String {
        "\(TSFormat.time(startsAt)) – \(TSFormat.time(endsAt))"
    }

    /// 07-7 목록 "15:00 – 16:00 · 온라인"
    var listMetaText: String {
        "\(timeText) · \(place)"
    }

    /// 07-9 "10월 14일 (화)"
    var dayText: String {
        "\(TSFormat.monthDay(startsAt)) (\(TSFormat.shortWeekday(startsAt)))"
    }

    /// 07-9 "온라인 · Discode"
    var placeText: String {
        [place, placeDetail].compactMap { $0 }.joined(separator: " · ")
    }

    /// 07-9 "참여 6명 · 주최자 이시우"
    var peopleText: String {
        "참여 \(participantCount)명 · 주최자 \(organizerName)"
    }

    /// 07-9 "Native 일정 · 변경됨"
    var badgeText: String {
        isChanged ? "\(scope.title) · 변경됨" : scope.title
    }

    /// 목록 왼쪽 색 막대 — 개인 업무는 파랑, Native 일정은 보라
    var tint: Color {
        scope == .team ? .tsViolet : .tsPrimary
    }

    /// 07-8 "2026.10.24 14:00–16:00"
    var fullTimeText: String {
        "\(TSFormat.fullDate(startsAt)) \(TSFormat.timeRange(startsAt, endsAt))"
    }

    /// Native 일정은 07-8 전체 일정 상세, 나머지는 07-9 시트로 열어요.
    var opensFullDetail: Bool {
        scope == .team
    }
}

extension ScheduleResponse {
    var title: String {
        switch self {
        case .attend: return "참석"
        case .decline: return "불참"
        case .undecided, .unknown: return "미정"
        }
    }
}

extension ReminderTiming {
    var title: String {
        switch self {
        case .dayBefore: return "하루 전"
        case .hourBefore: return "1시간 전"
        case .tenMinutesBefore: return "10분 전"
        case .unknown: return "알림"
        }
    }

    /// "하루 전 · 1시간 전" / "알림 없음"
    static func summary(_ reminders: [ReminderTiming]) -> String {
        reminders.isEmpty ? "알림 없음" : reminders.map(\.title).joined(separator: " · ")
    }
}

extension ScheduleAgendaItem {
    /// "14:00–14:20　팀 운영 소식 공유"
    var text: String {
        "\(TSFormat.timeRange(startsAt, endsAt))　\(title)"
    }
}

/// 07-7 달력 한 칸 (앞쪽 빈칸은 date == nil)
struct CalendarDay: Identifiable, Equatable {
    let id: Int
    let date: Date?
}
