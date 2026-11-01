import Foundation

/// 07-8 일정 상세
struct FetchScheduleDetailUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(id: Int) async throws -> ScheduleEventDetail {
        try await workspaceRepository.fetchScheduleDetail(id: id)
    }
}
