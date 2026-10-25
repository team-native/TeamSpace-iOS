import Foundation

/// 08-1 전체 프로젝트 — 최근 업데이트순
struct FetchProjectsUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute() async throws -> [ProjectSummary] {
        try await projectRepository.fetchProjects().sorted { $0.updatedAt > $1.updatedAt }
    }
}
