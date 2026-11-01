import Foundation
import Observation

/// 08-6 내 참여 신청 현황
@Observable
@MainActor
final class MyApplicationsViewModel {
    private(set) var state: ViewState<[ProjectApplication]> = .idle
    var filter: ApplicationFilter = .all
    /// 자세히 펼친 신청 (처음에는 검토 중인 신청)
    var expandedIds: Set<Int> = []
    /// 취소 확인을 기다리는 신청
    var pendingCancel: ProjectApplication?
    var errorMessage: String?

    private let fetchMyApplicationsUseCase: FetchMyApplicationsUseCase
    private let cancelApplicationUseCase: CancelApplicationUseCase

    init(fetchMyApplicationsUseCase: FetchMyApplicationsUseCase, cancelApplicationUseCase: CancelApplicationUseCase) {
        self.fetchMyApplicationsUseCase = fetchMyApplicationsUseCase
        self.cancelApplicationUseCase = cancelApplicationUseCase
    }

    private var all: [ProjectApplication] { state.value ?? [] }

    var applications: [ProjectApplication] {
        guard let status = filter.status else { return all }
        return all.filter { $0.status == status }
    }

    func count(of filter: ApplicationFilter) -> Int {
        guard let status = filter.status else { return all.count }
        return all.filter { $0.status == status }.count
    }

    func isExpanded(_ application: ProjectApplication) -> Bool {
        expandedIds.contains(application.id)
    }

    func toggle(_ application: ProjectApplication) {
        if expandedIds.contains(application.id) {
            expandedIds.remove(application.id)
        } else {
            expandedIds.insert(application.id)
        }
    }

    func load() async {
        let isFirstLoad = state.value == nil
        if isFirstLoad { state = .loading }
        do {
            let applications = try await fetchMyApplicationsUseCase.execute()
            state = .loaded(applications)
            if isFirstLoad {
                expandedIds = Set(applications.filter { $0.status == .reviewing }.map(\.id))
            }
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.applications.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 확인 창에서 "신청 취소"
    func confirmCancel() async {
        guard let application = pendingCancel else { return }
        pendingCancel = nil
        do {
            try await cancelApplicationUseCase.execute(application)
            state = .loaded(all.filter { $0.id != application.id })
        } catch {
            AppLog.record(error, context: "project.applications.cancel")
            errorMessage = error.userMessage
        }
    }
}
