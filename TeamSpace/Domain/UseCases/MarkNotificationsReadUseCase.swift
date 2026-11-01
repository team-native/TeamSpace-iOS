import Foundation

/// 알림 읽음 처리 — 알림을 읽은 것은 결재 승인 · 업무 완료가 아닙니다.
struct MarkNotificationsReadUseCase {
    private let notificationRepository: NotificationRepository

    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }

    /// 여러 개를 읽음 처리하고, 성공한 ID 만 돌려줍니다.
    /// TODO: 명세서에 '모두 읽음' API 가 없어 개별 API 를 순서대로 호출 — 일괄 API 생기면 교체
    func execute(ids: [Int]) async -> (succeeded: [Int], failure: Error?) {
        var succeeded: [Int] = []
        var lastError: Error?
        for id in ids {
            do {
                try await notificationRepository.markAsRead(id: id)
                succeeded.append(id)
            } catch {
                lastError = error
            }
        }
        return (succeeded, lastError)
    }
}
