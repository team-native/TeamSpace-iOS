import Foundation
import Observation

/// 07-7 일정 (달력) · 07-9 일정 상세 시트
@Observable
@MainActor
final class ScheduleCalendarViewModel {
    private(set) var state: ViewState<[ScheduleEvent]> = .idle
    private(set) var month: Date
    private(set) var selectedDate: Date
    /// 07-9 시트로 보고 있는 일정
    var sheetEvent: ScheduleEvent?
    var errorMessage: String?

    private let fetchSchedulesUseCase: FetchSchedulesUseCase
    private let respondScheduleUseCase: RespondScheduleUseCase
    private let calendar: Calendar
    private let now: () -> Date

    init(
        fetchSchedulesUseCase: FetchSchedulesUseCase,
        respondScheduleUseCase: RespondScheduleUseCase,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.fetchSchedulesUseCase = fetchSchedulesUseCase
        self.respondScheduleUseCase = respondScheduleUseCase
        self.calendar = calendar
        self.now = now
        let today = calendar.startOfDay(for: now())
        self.month = calendar.startOfMonth(for: today)
        self.selectedDate = today
    }

    private var events: [ScheduleEvent] { state.value ?? [] }

    var monthTitle: String { TSFormat.yearMonth(month) }

    /// "10월 14일 화요일"
    var selectedTitle: String {
        "\(TSFormat.monthDay(selectedDate)) \(TSFormat.weekday(selectedDate))"
    }

    /// 일요일부터 시작하는 달력 칸
    var days: [CalendarDay] {
        let leading = (calendar.component(.weekday, from: month) - 1 + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let blanks = (0..<leading).map { CalendarDay(id: -$0 - 1, date: nil) }
        let dates = (0..<count).map { offset in
            CalendarDay(id: offset + 1, date: calendar.date(byAdding: .day, value: offset, to: month))
        }
        return blanks + dates
    }

    func events(on date: Date) -> [ScheduleEvent] {
        events.filter { calendar.isDate($0.startsAt, inSameDayAs: date) }
    }

    var selectedEvents: [ScheduleEvent] { events(on: selectedDate) }

    func isSelected(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: selectedDate) }
    func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: now()) }

    func select(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchSchedulesUseCase.execute(month: month))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.schedules.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 이전 · 다음 달 — 오늘이 있는 달이면 오늘, 아니면 1일을 골라요.
    func showMonth(offset: Int) async {
        guard let next = calendar.date(byAdding: .month, value: offset, to: month) else { return }
        month = next
        let today = calendar.startOfDay(for: now())
        selectedDate = calendar.isDate(today, equalTo: next, toGranularity: .month) ? today : next
        state = .loading
        await load()
    }

    /// 07-9 참석할게요 · 불참
    func respond(_ response: ScheduleResponse) async {
        guard let event = sheetEvent else { return }
        do {
            let updated = try await respondScheduleUseCase.execute(event, response: response, now: now())
            state = .loaded(events.map { $0.id == updated.id ? updated : $0 })
            sheetEvent = nil
        } catch {
            AppLog.record(error, context: "workspace.schedules.respond")
            sheetEvent = nil
            errorMessage = error.userMessage
        }
    }
}
