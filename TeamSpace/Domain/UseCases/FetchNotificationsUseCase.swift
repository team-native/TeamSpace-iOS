import Foundation

struct FetchNotificationsUseCase {
    /// 서버 기본값과 같은 한 페이지 개수
    static let defaultPageSize = 20

    private let notificationRepository: NotificationRepository
    private let pageSize: Int

    init(notificationRepository: NotificationRepository, pageSize: Int = Self.defaultPageSize) {
        self.notificationRepository = notificationRepository
        self.pageSize = pageSize
    }

    /// 한 페이지를 최신순으로 돌려줍니다. (명세서: 30일이 지난 알림은 서버에서 정리)
    func execute(cursor: String? = nil) async throws -> CursorPage<AppNotification> {
        let page = try await notificationRepository.fetchNotifications(cursor: cursor, limit: pageSize)
        return CursorPage(items: page.items.sorted { $0.createdAt > $1.createdAt }, nextCursor: page.nextCursor)
    }
}
