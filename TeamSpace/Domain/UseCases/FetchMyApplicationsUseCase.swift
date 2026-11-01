import Foundation

/// 08-6 내 참여 신청 — 최근 신청이 위로 (취소한 신청은 빼요)
struct FetchMyApplicationsUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute() async throws -> [ProjectApplication] {
        try await projectRepository.fetchMyApplications()
            .filter { $0.status != .canceled }
            .sorted { $0.appliedAt > $1.appliedAt }
    }
}
