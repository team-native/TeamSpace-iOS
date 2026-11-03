import Foundation

/// 일정 수정 — Admin 만, 등록과 같은 확인 뒤 PATCH /admin/events/{id}
struct UpdateScheduleUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(id: Int, _ draft: ScheduleDraft, user: AuthUser, calendar: Calendar = .current) async throws {
        guard user.can(.manageEvents) else { throw AppError.forbidden("일정은 관리자만 수정할 수 있어요.") }
        try await workspaceRepository.updateSchedule(id: id, CreateScheduleUseCase.validated(draft, calendar: calendar))
    }
}
