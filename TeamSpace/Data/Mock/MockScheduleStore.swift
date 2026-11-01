import Foundation

/// Mock 일정 — Figma 07-7 ~ 07-9 예시. 참석 응답 · 리마인더를 메모리에 기억해요.
/// 날짜는 오늘 기준이라 언제 실행해도 이번 달 달력에 일정이 보여요.
/// 일정 1 · 2 는 07-1 대시보드 · 07-2 To-do 의 일정과 같아요.
final class MockScheduleStore: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [ScheduleEventDTO]
    private var reminders: [Int: [ReminderTiming]] = [2: [.dayBefore, .hourBefore]]
    private let now: Date
    private let calendar: Calendar

    init(now: Date = Date(), calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        func at(_ days: Int, _ hour: Double) -> Date {
            (calendar.date(byAdding: .day, value: days, to: today) ?? today).addingTimeInterval(hour * 3_600)
        }
        func event(
            _ id: Int, _ scope: WorkspaceScheduleScope, _ title: String, day: Int, from: Double, to: Double,
            place: String, detail: String?, organizer: String, people: Int, changed: Bool = false
        ) -> ScheduleEventDTO {
            ScheduleEventDTO(
                id: id, scope: scope, title: title, startsAt: at(day, from), endsAt: at(day, to), place: place,
                placeDetail: detail, organizerName: organizer, participantCount: people, isChanged: changed,
                myResponse: nil, respondedAt: nil
            )
        }
        events = [
            event(3, .personal, "Book-on 디자인 리뷰", day: 0, from: 15, to: 16, place: "온라인", detail: "Discode",
                  organizer: "이시우", people: 6, changed: true),
            event(4, .team, "iOS 스터디", day: 0, from: 18, to: 19, place: "3층 라운지", detail: nil, organizer: "오잉", people: 8),
            event(5, .personal, "디자인 시스템 정리", day: -5, from: 10, to: 11, place: "온라인", detail: "Figma",
                  organizer: "옥물결", people: 3),
            event(1, .personal, "Book-on QA 점검", day: 7, from: 15, to: 16, place: "온라인", detail: "Discode",
                  organizer: "이시우", people: 6, changed: true),
            event(2, .team, "Native 전체 회의", day: 8, from: 14, to: 16, place: "4층 홈베이스", detail: nil,
                  organizer: "NativeOps", people: 42, changed: true)
        ]
        events[4].myResponse = .attend
        events[4].respondedAt = at(-2, 9.33)
    }

    /// GET /workspace/schedules?month= — 그 달에 시작하는 일정
    func listJSON(monthText: String?) -> String {
        lock.lock()
        defer { lock.unlock() }
        let month = monthText.flatMap(FinanceMonthParameter.date(from:)) ?? now
        let list = events.filter { calendar.isDate($0.startsAt, equalTo: month, toGranularity: .month) }
        return envelope(encode(["list": list]))
    }

    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let event = events.first(where: { $0.id == id }) else { return nil }
        return envelope(encode(detail(for: event)))
    }

    func respond(id: Int, response: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = events.firstIndex(where: { $0.id == id }) else { return nil }
        events[index].myResponse = ScheduleResponse(rawValue: response) ?? .undecided
        events[index].respondedAt = Date()
        return envelope(encode(events[index]))
    }

    func updateReminders(id: Int, values: [String]) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard events.contains(where: { $0.id == id }) else { return nil }
        reminders[id] = values.compactMap(ReminderTiming.init(rawValue:))
        return envelope(encode(ScheduleRemindersDTO(reminders: reminders[id, default: []].map(\.rawValue))))
    }

    private func detail(for event: ScheduleEventDTO) -> ScheduleDetailDTO {
        let isMeeting = event.id == 2
        func time(_ minutes: Double) -> Date { event.startsAt.addingTimeInterval(minutes * 60) }
        let agenda: [ScheduleDetailDTO.AgendaDTO] = isMeeting ? [
            .init(startsAt: time(0), endsAt: time(20), title: "팀 운영 소식 공유"),
            .init(startsAt: time(20), endsAt: time(60), title: "전공별 멘토링 현황 진행 공유"),
            .init(startsAt: time(60), endsAt: time(90), title: "다음 달 활동 계획 논의"),
            .init(startsAt: time(90), endsAt: time(120), title: "질문과 의견 나누기")
        ] : []
        let registered = event.startsAt.addingTimeInterval(-14 * 86_400)
        let moved = event.startsAt.addingTimeInterval(-9 * 86_400)
        return ScheduleDetailDTO(
            event: event,
            category: event.scope == .team ? "정기 활동" : "프로젝트 일정",
            summary: isMeeting
                ? "팀의 진행 상황을 나누고 다음 달에 함께할 일을 정해요."
                : "\(event.title) 일정이에요. 시간과 장소를 확인해 주세요.",
            host: event.organizerName,
            audience: event.scope == .team ? "Native 전체 구성원" : "프로젝트 참여자",
            facilitator: isMeeting ? "양지우 · NativeOps" : event.organizerName,
            agenda: agenda,
            agendaNote: isMeeting ? "프로젝트별 공유 자료는 회의 전날까지 연결된 문서에 남겨주세요." : nil,
            relatedDocument: isMeeting
                ? .init(title: "정기 회의 안건·공유 자료", owner: "NativeOps", updatedAt: moved)
                : nil,
            history: event.isChanged ? [
                .init(title: "장소 변경", changedAt: moved, detail: "3층 회의실 → \(event.place)\n수정자 양지우 · 참석 인원 증가"),
                .init(title: "일정 등록", changedAt: registered, detail: event.organizerName)
            ] : [.init(title: "일정 등록", changedAt: registered, detail: event.organizerName)],
            historyNote: event.scope == .team ? "전체 구성원에게 ‘Native 일정’ 알림을 생성했어요." : nil,
            reminders: reminders[event.id, default: []]
        )
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONCoder.makeEncoder().encode(value) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }

    private func envelope(_ data: String) -> String {
        #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
