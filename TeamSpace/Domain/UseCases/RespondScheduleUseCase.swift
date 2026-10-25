import Foundation

/// 07-8 · 07-9 참석 응답 — 끝난 일정에는 응답할 수 없어요.
struct RespondScheduleUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(_ event: ScheduleEvent, response: ScheduleResponse, now: Date = Date()) async throws -> ScheduleEvent {
        guard response != .unknown else { throw AppError.invalidInput("참석 여부를 골라 주세요.") }
        guard event.endsAt > now else { throw AppError.invalidInput("이미 끝난 일정이에요.") }
        return try await workspaceRepository.respond(scheduleId: event.id, response: response)
    }
}
