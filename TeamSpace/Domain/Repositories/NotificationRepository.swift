import Foundation

protocol NotificationRepository: Sendable {
    /// GET /notifications
    func fetchNotifications(page: Int, limit: Int) async throws -> [AppNotification]
    /// PATCH /notifications/{notificationId}/read
    func markAsRead(id: Int) async throws
}
