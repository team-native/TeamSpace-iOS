import Foundation

/// 10-6 공지 삭제 — Admin 만 (서버 `DELETE /admin/notices/{id}`)
struct DeleteNoticeUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(noticeId: Int, user: AuthUser?) async throws {
        guard user?.can(.deleteNotices) == true else { throw AppError.forbidden("공지 삭제는 관리자만 할 수 있어요.") }
        try await noticeRepository.delete(noticeId: noticeId)
    }
}

/// 07-8 일정 삭제 — Admin 만 (서버 `DELETE /admin/events/{id}`)
struct DeleteScheduleUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(scheduleId: Int, user: AuthUser?) async throws {
        guard user?.can(.manageEvents) == true else { throw AppError.forbidden("일정 삭제는 관리자만 할 수 있어요.") }
        try await workspaceRepository.deleteSchedule(id: scheduleId)
    }
}
