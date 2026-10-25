import Foundation

/// 08-8 프로젝트 일정 — 마일스톤 · 내 일정은 날짜 순, 변경 이력은 최근 순
struct FetchProjectTimelineUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(projectId: Int) async throws -> ProjectTimeline {
        let timeline = try await projectRepository.fetchTimeline(projectId: projectId)
        return ProjectTimeline(
            projectName: timeline.projectName,
            status: timeline.status,
            isJoined: timeline.isJoined,
            milestones: timeline.milestones.sorted { $0.date < $1.date },
            mySchedules: timeline.mySchedules.sorted { $0.startsAt < $1.startsAt },
            changes: timeline.changes.sorted { $0.changedAt > $1.changedAt }
        )
    }
}
