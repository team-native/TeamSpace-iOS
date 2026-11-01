import Foundation

/// 08-3 모집 공고
struct FetchRecruitmentUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(projectId: Int) async throws -> RecruitmentPost {
        try await projectRepository.fetchRecruitment(projectId: projectId)
    }
}
