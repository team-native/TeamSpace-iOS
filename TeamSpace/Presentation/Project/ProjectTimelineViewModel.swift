import Foundation
import Observation

/// 08-8 프로젝트 일정과 변경 이력
@Observable
@MainActor
final class ProjectTimelineViewModel {
    enum Section: CaseIterable, Hashable {
        case milestones
        case mySchedules
        case changes

        var title: String {
            switch self {
            case .milestones: return "마일스톤"
            case .mySchedules: return "내 일정"
            case .changes: return "변경 이력"
            }
        }
    }

    private(set) var state: ViewState<ProjectTimeline> = .idle
    var selectedSection: Section = .changes
    /// 펼쳐 본 지난 변경
    var expandedChangeIds: Set<Int> = []

    private let projectId: Int
    private let fetchProjectTimelineUseCase: FetchProjectTimelineUseCase

    init(projectId: Int, fetchProjectTimelineUseCase: FetchProjectTimelineUseCase) {
        self.projectId = projectId
        self.fetchProjectTimelineUseCase = fetchProjectTimelineUseCase
    }

    var timeline: ProjectTimeline? { state.value }

    /// "Book-on의 다음 단계"
    var title: String {
        "\(timeline?.projectName ?? "프로젝트")의 다음 단계"
    }

    /// "진행 중 · 내 참여 프로젝트"
    var badgeText: String {
        guard let timeline else { return "" }
        return timeline.isJoined ? "\(timeline.status.badgeTitle) · 내 참여 프로젝트" : timeline.status.badgeTitle
    }

    var latestChange: ProjectScheduleChange? { timeline?.changes.first }
    var olderChanges: [ProjectScheduleChange] { Array((timeline?.changes ?? []).dropFirst()) }

    func toggle(_ change: ProjectScheduleChange) {
        if expandedChangeIds.contains(change.id) {
            expandedChangeIds.remove(change.id)
        } else {
            expandedChangeIds.insert(change.id)
        }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchProjectTimelineUseCase.execute(projectId: projectId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.timeline.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
