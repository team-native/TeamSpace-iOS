import Foundation

/// 02-1 홈 — /dashboard/home 을 기준으로, 공지 3개와 (FA 라면) 재정 요약을 함께 불러와요.
final class DashboardRepositoryImpl: DashboardRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchHome() async throws -> DashboardHome {
        async let noticesTask = fetchNotices()
        let home: ServerDashboardHomeDTO
        do {
            home = try await client.request(Endpoint(method: .get, path: "dashboard/home"), as: ServerDashboardHomeDTO.self)
        } catch let error as NetworkError {
            throw error.asAppError
        }
        let finance = home.canSeeFinance ? await fetchFinance() : nil
        return home.toEntity(
            finance: finance?.toHomeFinance(),
            contracts: finance?.toHomeContracts(),
            notices: await noticesTask
        )
    }

    /// 공지를 못 불러오면 대시보드의 최신 공지 하나만 보여줘요.
    private func fetchNotices() async -> [NoticePreview]? {
        let endpoint = Endpoint(method: .get, path: "notices", queryItems: [URLQueryItem(name: "limit", value: "3")])
        do {
            let page = try await client.request(endpoint, as: CursorPageDTO<ServerNoticeItemDTO>.self)
            return page.items.prefix(3).map { $0.toPreview() }
        } catch {
            AppLog.record(error, context: "dashboard.notices")
            return nil
        }
    }

    /// 재정 요약이 실패해도 홈의 나머지는 보여줘요.
    private func fetchFinance() async -> ServerFinanceSummaryDTO? {
        do {
            return try await client.request(Endpoint(method: .get, path: "finance/summary"), as: ServerFinanceSummaryDTO.self)
        } catch {
            AppLog.record(error, context: "dashboard.finance")
            return nil
        }
    }
}
