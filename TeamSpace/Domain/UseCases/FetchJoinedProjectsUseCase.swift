import Foundation

/// 07-6 참여 프로젝트 — 진행 중인 것이 먼저, 그다음 끝나는 날이 가까운 순
struct FetchJoinedProjectsUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> [JoinedProject] {
        try await workspaceRepository.fetchJoinedProjects().sorted {
            let left = $0.status == .inProgress ? 0 : 1
            let right = $1.status == .inProgress ? 0 : 1
            return left == right ? $0.endDate < $1.endDate : left < right
        }
    }
}
