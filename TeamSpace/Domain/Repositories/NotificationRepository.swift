import Foundation

protocol NotificationRepository: Sendable {
    /// GET /notifications?cursor=&limit= — 최신순 한 페이지 (`cursor` 는 앞 페이지의 `nextCursor`, 첫 페이지는 nil)
    func fetchNotifications(cursor: String?, limit: Int) async throws -> CursorPage<AppNotification>
    /// PATCH /notifications/{notificationId}/read
    func markAsRead(id: Int) async throws
}
