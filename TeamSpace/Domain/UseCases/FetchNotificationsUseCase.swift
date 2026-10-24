import Foundation

struct FetchNotificationsUseCase {
    private let notificationRepository: NotificationRepository

    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    /// 최신순으로 돌려줍니다. (명세서: 30일이 지난 알림은 서버에서 정리)
    func execute(page: Int = 1, limit: Int = 50) async throws -> [AppNotification] {
        try await notificationRepository.fetchNotifications(page: page, limit: limit)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
