import Foundation

/// 07-1 내 공간 대시보드 — 일정은 가까운 순으로 정렬합니다.
struct FetchWorkspaceHomeUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> WorkspaceHome {
        let home = try await workspaceRepository.fetchHome()
        return WorkspaceHome(
            affiliation: home.affiliation,
            todo: home.todo,
            notification: home.notification,
            receivedApproval: home.receivedApproval,
            submittedDocument: home.submittedDocument,
            projects: home.projects,
            schedules: home.schedules.sorted { $0.startsAt < $1.startsAt },
            records: home.records
        )
    }
}
