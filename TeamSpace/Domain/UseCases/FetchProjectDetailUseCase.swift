import Foundation

/// 08-2 프로젝트 상세
struct FetchProjectDetailUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(id: Int) async throws -> ProjectDetail {
        try await projectRepository.fetchProjectDetail(id: id)
    }
}
