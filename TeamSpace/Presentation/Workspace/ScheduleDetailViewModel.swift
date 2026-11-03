import Foundation
import Observation

/// 07-8 전체 일정 상세
@Observable
@MainActor
final class ScheduleDetailViewModel {
    private(set) var state: ViewState<ScheduleEventDetail> = .idle
    var isReminderEditorPresented = false
    /// 리마인더 변경 시트에서 고르는 중인 값
    var draftReminders: Set<ReminderTiming> = []
    private(set) var isSaving = false
    var errorMessage: String?

    private let scheduleId: Int
    private let fetchScheduleDetailUseCase: FetchScheduleDetailUseCase
    private let respondScheduleUseCase: RespondScheduleUseCase
    private let updateRemindersUseCase: UpdateRemindersUseCase
    private let user: AuthUser?

    init(
        scheduleId: Int,
        fetchScheduleDetailUseCase: FetchScheduleDetailUseCase,
        respondScheduleUseCase: RespondScheduleUseCase,
        updateRemindersUseCase: UpdateRemindersUseCase,
        user: AuthUser? = nil
    ) {
        self.scheduleId = scheduleId
        self.user = user
        self.fetchScheduleDetailUseCase = fetchScheduleDetailUseCase
        self.respondScheduleUseCase = respondScheduleUseCase
        self.updateRemindersUseCase = updateRemindersUseCase
    }

    var detail: ScheduleEventDetail? { state.value }

    /// 일정 수정 (서버 `require_admin` — Admin 만)
    var canEdit: Bool { detail != nil && user?.can(.manageEvents) == true }

    /// "내 응답 저장됨 · 10.16 09:20"
    var savedResponseText: String? {
        guard let event = detail?.event, event.myResponse != nil else { return nil }
        // 서버(GET /events)는 응답 시각을 주지 않아요 — 이번에 응답했을 때만 시각을 보여줘요.
        guard let respondedAt = event.respondedAt else { return "내 응답 저장됨" }
        return "내 응답 저장됨 · \(TSFormat.shortDate(respondedAt)) \(TSFormat.time(respondedAt))"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchScheduleDetailUseCase.execute(id: scheduleId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.schedule.detail")
            if state.value == nil { state = .failed(error) }
        }
    }

    func respond(_ response: ScheduleResponse) async {
        guard var detail = detail else { return }
        do {
            detail.event = try await respondScheduleUseCase.execute(detail.event, response: response)
            state = .loaded(detail)
        } catch {
            AppLog.record(error, context: "workspace.schedule.respond")
            errorMessage = error.userMessage
        }
    }

    func openReminderEditor() {
        draftReminders = Set(detail?.reminders ?? [])
        isReminderEditorPresented = true
    }

    func toggleReminder(_ timing: ReminderTiming) {
        if draftReminders.contains(timing) {
            draftReminders.remove(timing)
        } else {
            draftReminders.insert(timing)
        }
    }

    func saveReminders() async {
        guard var detail = detail, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            detail.reminders = try await updateRemindersUseCase.execute(
                scheduleId: detail.event.id,
                reminders: Array(draftReminders)
            )
            state = .loaded(detail)
            isReminderEditorPresented = false
        } catch {
            AppLog.record(error, context: "workspace.schedule.reminders")
            errorMessage = error.userMessage
        }
    }
}
