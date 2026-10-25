import Foundation

/// 07-7 한 달 일정 — 시작 시간 순
struct FetchSchedulesUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(month: Date) async throws -> [ScheduleEvent] {
        try await workspaceRepository.fetchSchedules(month: month).sorted { $0.startsAt < $1.startsAt }
    }
}
