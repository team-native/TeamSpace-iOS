import Foundation

/// GET /events?month= 의 한 항목 (TeamSpace-backend develop `space.get_events`)
/// 일정 payload 는 관리자가 넣은 값 그대로예요. 프론트 관리자 화면 기준으로
/// date(YYYY-MM-DD) · start · end(HH:mm) · time(표시 문자열) · place · host · agenda · scope · rsvp 를 읽어요.
struct ServerEventDTO: Decodable {
    let id: Int
    let title: String
    let date: String
    let start: String?
    let end: String?
    let time: String?
    let place: String?
    let host: String?
    let agenda: String?
    /// 팀 · 프로젝트 · 개인
    let scope: String?
    /// 참석 응답을 받는 일정인지
    let rsvpEnabled: Bool
    /// 참석 · 불참 · 미정
    let myRsvp: String?
    let rsvpCount: Int
    /// 내 참석 응답 시각 (GET /events/{id} · 목록 모두)
    let respondedAt: Date?
    /// 대상 — "전체" · "PMO" 등
    let audience: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        date = (try? container.decodeIfPresent(String.self, forKey: .date)) ?? ""
        start = try? container.decodeIfPresent(String.self, forKey: .start)
        end = try? container.decodeIfPresent(String.self, forKey: .end)
        time = try? container.decodeIfPresent(String.self, forKey: .time)
        place = try? container.decodeIfPresent(String.self, forKey: .place)
        host = try? container.decodeIfPresent(String.self, forKey: .host)
        agenda = try? container.decodeIfPresent(String.self, forKey: .agenda)
        scope = (try? container.decodeIfPresent(String.self, forKey: .scope)) ?? (try? container.decodeIfPresent(String.self, forKey: .kind))
        rsvpEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .rsvp)) ?? false
        myRsvp = try? container.decodeIfPresent(String.self, forKey: .myRsvp)
        rsvpCount = (try? container.decodeIfPresent(Int.self, forKey: .rsvpCount)) ?? 0
        respondedAt = (try? container.decodeIfPresent(String.self, forKey: .respondedAt)).flatMap { $0.flatMap(ServerDate.parse) }
        audience = try? container.decodeIfPresent(String.self, forKey: .audience)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, start, end, time, place, host, agenda, scope, kind, rsvp, myRsvp, rsvpCount, respondedAt, audience
    }

    /// 시작 · 끝 시각 — start/end 가 없으면 time 문자열의 "HH:mm" 을 차례로 써요. 시간이 없으면 종일(0시 ~ 23:59)
    var period: (start: Date, end: Date)? {
        guard let day = ServerTodoDTO.date(fromDay: date) else { return nil }
        let times = [start, end].compactMap { $0 }.isEmpty ? Self.clockTimes(in: time ?? "") : [start, end].compactMap { $0 }
        let startsAt = times.first.flatMap { Self.time($0, on: day) } ?? day
        let endsAt = times.dropFirst().first.flatMap { Self.time($0, on: day) }
            ?? (times.isEmpty ? day.addingTimeInterval(86_399) : startsAt.addingTimeInterval(3_600))
        return (startsAt, max(endsAt, startsAt))
    }

    func toEntity() -> ScheduleEvent? {
        guard let period else { return nil }
        let parts = (place ?? "").components(separatedBy: " · ")
        return ScheduleEvent(
            id: id,
            scope: scope == "팀" || scope == "team" ? .team : .personal,
            title: title,
            startsAt: period.start,
            endsAt: period.end,
            place: parts.first ?? "",
            placeDetail: parts.count > 1 ? parts.dropFirst().joined(separator: " · ") : nil,
            organizerName: host ?? "",
            participantCount: rsvpCount,
            isChanged: false,
            myResponse: myRsvp.flatMap(ScheduleResponse.init(serverValue:)),
            respondedAt: respondedAt
        )
    }

    /// 07-8 상세 — 서버는 진행자 · 변경 이력 내용을 따로 주지 않아요.
    /// agenda 의 "14:00–14:20 제목" 줄은 안건 시간표로, 나머지는 안건 메모로 보여줘요.
    func toDetail(reminders: [ReminderTiming]) -> ScheduleEventDetail? {
        guard let event = toEntity() else { return nil }
        let day = Calendar(identifier: .gregorian).startOfDay(for: event.startsAt)
        var items: [ScheduleAgendaItem] = []
        var notes: [String] = []
        for line in (agenda ?? "").components(separatedBy: .newlines).map({ $0.trimmingCharacters(in: .whitespaces) }) where !line.isEmpty {
            let times = Self.clockTimes(in: line)
            if times.count >= 2, let from = Self.time(times[0], on: day), let to = Self.time(times[1], on: day),
               let range = line.range(of: times[1]) {
                let title = line[range.upperBound...].trimmingCharacters(in: CharacterSet(charactersIn: " ·-–"))
                items.append(ScheduleAgendaItem(startsAt: from, endsAt: to, title: title))
            } else {
                notes.append(line)
            }
        }
        let scopeTitle = event.scope == .team ? "팀 일정" : "프로젝트 일정"
        return ScheduleEventDetail(
            event: event,
            category: scope ?? scopeTitle,
            summary: notes.first ?? "\(title) 일정이에요.",
            host: host ?? "",
            audience: audience.map { $0 == "전체" ? "전체 구성원" : $0 } ?? (event.scope == .team ? "전체 구성원" : "참여자"),
            facilitator: host ?? "",
            agenda: items,
            agendaNote: notes.count > 1 ? notes.dropFirst().joined(separator: "\n") : nil,
            relatedDocument: nil,
            history: [],
            historyNote: nil,
            reminders: reminders
        )
    }

    static func clockTimes(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"\b([01]?\d|2[0-3]):[0-5]\d\b"#) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    /// "19:00" → 그날 19시 (서울)
    static func time(_ clock: String, on day: Date) -> Date? {
        let parts = clock.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return day.addingTimeInterval(TimeInterval(parts[0] * 3_600 + parts[1] * 60))
    }
}

/// POST /events/{id}/rsvp 요청
struct ServerRsvpRequestDTO: Codable, Equatable {
    let rsvp: String
    var reason: String?
}

extension ScheduleResponse {
    init?(serverValue: String) {
        switch serverValue {
        case "참석": self = .attend
        case "불참": self = .decline
        case "미정": self = .undecided
        default: return nil
        }
    }

    var serverValue: String {
        switch self {
        case .attend: return "참석"
        case .decline: return "불참"
        case .undecided, .unknown: return "미정"
        }
    }
}

/// GET · PATCH /events/{id}/reminders — `{ eventId, oneDayBefore, oneHourBefore, tenMinutesBefore }`
struct ServerEventRemindersDTO: Codable, Equatable {
    var oneDayBefore: Bool
    var oneHourBefore: Bool
    var tenMinutesBefore: Bool

    private enum CodingKeys: String, CodingKey { case oneDayBefore, oneHourBefore, tenMinutesBefore }

    init(_ reminders: [ReminderTiming]) {
        oneDayBefore = reminders.contains(.dayBefore)
        oneHourBefore = reminders.contains(.hourBefore)
        tenMinutesBefore = reminders.contains(.tenMinutesBefore)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        oneDayBefore = (try? container.decodeIfPresent(Bool.self, forKey: .oneDayBefore)) ?? false
        oneHourBefore = (try? container.decodeIfPresent(Bool.self, forKey: .oneHourBefore)) ?? false
        tenMinutesBefore = (try? container.decodeIfPresent(Bool.self, forKey: .tenMinutesBefore)) ?? false
    }

    /// 이른 순 — 하루 전 · 1시간 전 · 10분 전
    var reminders: [ReminderTiming] {
        [(oneDayBefore, ReminderTiming.dayBefore), (oneHourBefore, .hourBefore), (tenMinutesBefore, .tenMinutesBefore)]
            .filter(\.0).map(\.1)
    }
}
