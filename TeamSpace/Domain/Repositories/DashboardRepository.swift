import Foundation

protocol DashboardRepository: Sendable {
    /// GET /dashboard/home
    func fetchHome() async throws -> DashboardHome
}
