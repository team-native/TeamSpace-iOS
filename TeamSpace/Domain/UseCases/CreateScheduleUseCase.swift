import Foundation

/// 일정 추가 — Admin 권한 · 제목 · 시각을 확인하고 POST /admin/events 로 등록해요.
struct CreateScheduleUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    @discardableResult
    func execute(_ draft: ScheduleDraft, user: AuthUser, calendar: Calendar = .current) async throws -> Int {
        guard user.can(.manageEvents) else { throw AppError.forbidden("일정은 관리자만 추가할 수 있어요.") }
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.place = draft.place.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.agenda = draft.agenda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.title.isEmpty, trimmed.title.count <= ScheduleDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(ScheduleDraft.titleLimit)자로 써 주세요.")
        }
        guard trimmed.agenda.count <= ScheduleDraft.agendaLimit else {
            throw AppError.invalidInput("안건은 \(ScheduleDraft.agendaLimit)자까지 쓸 수 있어요.")
        }
        guard Self.minutes(trimmed.endsAt, calendar) > Self.minutes(trimmed.startsAt, calendar) else {
            throw AppError.invalidInput("끝나는 시각은 시작 시각보다 뒤로 정해 주세요.")
        }
        return try await workspaceRepository.createSchedule(trimmed)
    }

    /// 하루 안의 분 (날짜는 따로 골라요)
    static func minutes(_ date: Date, _ calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}
