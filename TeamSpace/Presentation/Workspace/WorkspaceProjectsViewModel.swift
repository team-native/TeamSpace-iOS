import Foundation
import Observation

/// 07-6 참여 프로젝트
@Observable
@MainActor
final class WorkspaceProjectsViewModel {
    private(set) var state: ViewState<[JoinedProject]> = .idle

    private let fetchJoinedProjectsUseCase: FetchJoinedProjectsUseCase

    init(fetchJoinedProjectsUseCase: FetchJoinedProjectsUseCase) {
        self.fetchJoinedProjectsUseCase = fetchJoinedProjectsUseCase
    }

    var projects: [JoinedProject] {
        state.value ?? []
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let projects = try await fetchJoinedProjectsUseCase.execute()
            state = projects.isEmpty ? .empty : .loaded(projects)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.projects.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
