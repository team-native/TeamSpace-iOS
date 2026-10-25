import Foundation
import Observation

/// 08-2 프로젝트 상세
@Observable
@MainActor
final class ProjectDetailViewModel {
    private(set) var state: ViewState<ProjectDetail> = .idle
    let projectId: Int

    private let fetchProjectDetailUseCase: FetchProjectDetailUseCase

    init(projectId: Int, fetchProjectDetailUseCase: FetchProjectDetailUseCase) {
        self.projectId = projectId
        self.fetchProjectDetailUseCase = fetchProjectDetailUseCase
    }

    var detail: ProjectDetail? { state.value }

    /// 참여하지 않았고 모집 중일 때만 신청할 수 있어요.
    var canApply: Bool {
        guard let detail else { return false }
        return !detail.isJoined && detail.project.isRecruiting
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchProjectDetailUseCase.execute(id: projectId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
