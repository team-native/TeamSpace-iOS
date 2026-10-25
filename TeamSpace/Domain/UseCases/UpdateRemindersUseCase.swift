import Foundation

/// 07-8 내 리마인더 — 같은 시점은 한 번만, 이른 순으로 저장해요.
struct UpdateRemindersUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(scheduleId: Int, reminders: [ReminderTiming]) async throws -> [ReminderTiming] {
        let order = ReminderTiming.selectable
        let cleaned = order.filter { reminders.contains($0) }
        return try await workspaceRepository.updateReminders(scheduleId: scheduleId, reminders: cleaned)
    }
}
