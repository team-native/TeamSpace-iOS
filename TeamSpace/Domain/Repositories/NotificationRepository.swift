import Foundation

protocol NotificationRepository: Sendable {
    /// GET /notifications?cursor=&limit= — 최신순 한 페이지 (`cursor` 는 앞 페이지의 `nextCursor`, 첫 페이지는 nil)
    func fetchNotifications(cursor: String?, limit: Int) async throws -> CursorPage<AppNotification>
    /// POST /notifications/read `{ id }`
    func markAsRead(id: Int) async throws
    /// POST /notifications/read `{ all: true }` — 아직 안 불러온 페이지까지 모두 읽음
    func markAllAsRead() async throws
}
