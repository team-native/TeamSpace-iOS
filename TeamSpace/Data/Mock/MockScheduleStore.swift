import Foundation

/// Mock 일정 — 서버 develop `GET /events` · `GET /events/{id}` · `POST rsvp` · `GET · PATCH reminders` 형식.
/// 참석 응답 · 리마인더를 메모리에 기억해요.
/// 날짜는 오늘 기준이라 언제 실행해도 이번 달 달력에 일정이 보여요.
/// 일정 1 · 2 는 07-1 대시보드 · 07-2 To-do 의 일정과 같아요.
final class MockScheduleStore: @unchecked Sendable {
    private struct Event {
        let id: Int
        let scope: String
        let title: String
        let day: Date
        let start: String
        let end: String
        let place: String
        let host: String
        let agenda: String
        var rsvpCount: Int
        var myRsvp: String?
        var respondedAt: Date?
    }

    /// 일정별 내 리마인더 — 서버처럼 처음엔 모두 꺼져 있어요.
    private var reminders: [Int: [String: Bool]] = [:]

    private let lock = NSLock()
    private var events: [Event]
    private let calendar: Calendar

    init(now: Date = Date()) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today) ?? today }
        events = [
            Event(id: 3, scope: "개인", title: "Book-on 디자인 리뷰", day: day(0), start: "15:00", end: "16:00",
                  place: "온라인 · Discode", host: "이시우", agenda: "", rsvpCount: 6),
            Event(id: 4, scope: "팀", title: "iOS 스터디", day: day(0), start: "18:00", end: "19:00",
                  place: "3층 라운지", host: "오잉", agenda: "", rsvpCount: 8),
            Event(id: 5, scope: "개인", title: "디자인 시스템 정리", day: day(-5), start: "10:00", end: "11:00",
                  place: "온라인 · Figma", host: "옥물결", agenda: "", rsvpCount: 3),
            Event(id: 1, scope: "개인", title: "Book-on QA 점검", day: day(7), start: "15:00", end: "16:00",
                  place: "온라인 · Discode", host: "이시우", agenda: "", rsvpCount: 6),
            Event(id: 2, scope: "팀", title: "Native 전체 회의", day: day(8), start: "14:00", end: "16:00",
                  place: "4층 홈베이스", host: "NativeOps", agenda: """
                  팀의 진행 상황을 나누고 다음 달에 함께할 일을 정해요.
                  14:00–14:20 팀 운영 소식 공유
                  14:20–15:00 전공별 멘토링 현황 진행 공유
                  15:00–15:30 다음 달 활동 계획 논의
                  15:30–16:00 질문과 의견 나누기
                  프로젝트별 공유 자료는 회의 전날까지 남겨주세요.
                  """, rsvpCount: 42, myRsvp: "참석")
        ]
    }

    /// GET /events?month=YYYY-MM — 그 달 일정, 날짜 · 시작 시간 · id 순
    /// POST /admin/events — `{id}`. 날짜 · 시각 형식이 틀리면 nil (422)
    func create(_ request: ServerEventCreateRequestDTO) -> String? {
        lock.lock()
        defer { lock.unlock() }
        let parts = request.date.split(separator: "-").compactMap { Int($0) }
        guard
            parts.count == 3,
            let day = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
            ScheduleScope(rawValue: request.scope) != nil
        else { return nil }
        let id = (events.map(\.id).max() ?? 0) + 1
        events.append(Event(
            id: id, scope: request.scope, title: request.title, day: day, start: request.start, end: request.end,
            place: request.place, host: "관리자", agenda: request.agenda, rsvpCount: 0
        ))
        return json(["id": String(id)])
    }

    func listJSON(month: String?, cursor: String?, limit: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        let sorted = events
            .filter { month == nil || dayText($0.day).hasPrefix(month ?? "") }
            .sorted { ($0.day, $0.start, $0.id) < ($1.day, $1.start, $1.id) }
        let startIndex = cursor.flatMap { id in sorted.firstIndex { String($0.id) == id }.map { $0 + 1 } } ?? 0
        let page = Array(sorted.dropFirst(startIndex).prefix(limit))
        let next: Any = startIndex + page.count < sorted.count ? page.last.map { String($0.id) } ?? NSNull() : NSNull()
        return json(["items": page.map(fields), "nextCursor": next])
    }

    /// POST /events/{id}/rsvp — `{eventId, rsvp}`
    func rsvp(id: Int, value: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = events.firstIndex(where: { $0.id == id }) else { return nil }
        if events[index].myRsvp != "참석", value == "참석" { events[index].rsvpCount += 1 }
        if events[index].myRsvp == "참석", value != "참석" { events[index].rsvpCount -= 1 }
        events[index].myRsvp = value
        events[index].respondedAt = Date()
        return json(["eventId": String(id), "rsvp": value])
    }

    /// GET /events/{id}
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return events.first { $0.id == id }.map { json(fields($0)) }
    }

    /// GET /events/{id}/reminders · PATCH 는 보낸 값만 바꿔요.
    func remindersJSON(id: Int, patch: [String: Bool]? = nil) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard events.contains(where: { $0.id == id }) else { return nil }
        var values = reminders[id] ?? ["oneDayBefore": false, "oneHourBefore": false, "tenMinutesBefore": false]
        if let patch {
            for (key, value) in patch where values[key] != nil { values[key] = value }
            reminders[id] = values
        }
        var result: [String: Any] = values
        result["eventId"] = String(id)
        return json(result)
    }

    private func fields(_ event: Event) -> [String: Any] {
        [
            "id": String(event.id),
            "scope": event.scope,
            "title": event.title,
            "date": dayText(event.day),
            "start": event.start,
            "end": event.end,
            "place": event.place,
            "host": event.host,
            "agenda": event.agenda,
            "rsvp": true,
            "myRsvp": event.myRsvp ?? NSNull(),
            "respondedAt": event.respondedAt.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull(),
            "audience": event.scope == "팀" ? "전체" : "참여자",
            "rsvpCount": event.rsvpCount
        ]
    }

    private func dayText(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func json(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}
