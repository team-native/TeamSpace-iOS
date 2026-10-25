import Foundation

struct FetchDashboardHomeUseCase {
    private let dashboardRepository: DashboardRepository

    init(dashboardRepository: DashboardRepository) {
        self.dashboardRepository = dashboardRepository
    }

    /// 일정은 가까운 순, 프로젝트는 마감이 가까운 순으로 정렬합니다.
    func execute() async throws -> DashboardHome {
        let home = try await dashboardRepository.fetchHome()
        return DashboardHome(
            todayTaskCount: home.todayTaskCount,
            unreadNotificationCount: home.unreadNotificationCount,
            latestNotification: home.latestNotification,
            finance: home.finance,
            contracts: home.contracts,
            projects: home.projects.sorted { $0.dueDate < $1.dueDate },
            schedules: home.schedules.sorted { $0.startsAt < $1.startsAt },
            notices: home.notices
        )
    }
}
