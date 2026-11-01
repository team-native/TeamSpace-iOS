import Foundation
import Observation

/// 07-1 내 공간 대시보드 (내 공간 탭 첫 화면)
@Observable
@MainActor
final class WorkspaceHomeViewModel {
    private(set) var state: ViewState<WorkspaceHome> = .idle
    let user: AuthUser

    private let fetchWorkspaceHomeUseCase: FetchWorkspaceHomeUseCase

    init(user: AuthUser, fetchWorkspaceHomeUseCase: FetchWorkspaceHomeUseCase) {
        self.user = user
        self.fetchWorkspaceHomeUseCase = fetchWorkspaceHomeUseCase
    }

    var greeting: String {
        "\(user.name) 님, 오늘도 차근차근"
    }

    func dateLine(now: Date = Date()) -> String {
        "\(TSFormat.longDate(now)) · 나의 업무를 먼저 확인해요."
    }

    /// 예정 일정은 두 개까지만 보여줘요.
    static let scheduleLimit = 2

    var upcomingSchedules: [WorkspaceSchedule] {
        Array((state.value?.schedules ?? []).prefix(Self.scheduleLimit))
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchWorkspaceHomeUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.home.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
