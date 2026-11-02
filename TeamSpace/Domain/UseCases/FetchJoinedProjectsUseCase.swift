import Foundation

/// 07-6 참여 프로젝트 — 진행 중인 것이 먼저, 그다음은 서버 순서(최근 등록 순) 그대로
struct FetchJoinedProjectsUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> [JoinedProject] {
        let projects = try await workspaceRepository.fetchJoinedProjects()
        return projects.filter { $0.status == .inProgress } + projects.filter { $0.status != .inProgress }
    }
}
