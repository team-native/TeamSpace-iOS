import Foundation

/// Preview · 테스트용 알림 권한. 시스템 팝업 없이 정해진 결과를 돌려줍니다.
final class MockNotificationPermissionRepository: NotificationPermissionRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var status: NotificationPermissionStatus
    /// requestAuthorization() 에서 사용자가 누를 버튼 (true = 허용)
    private let grantsOnRequest: Bool
    private(set) var requestCount = 0

    init(status: NotificationPermissionStatus = .notDetermined, grantsOnRequest: Bool = true) {
        self.status = status
        self.grantsOnRequest = grantsOnRequest
    }

    func currentStatus() async -> NotificationPermissionStatus {
        lock.withLock { status }
    }

    func requestAuthorization() async throws -> NotificationPermissionStatus {
        lock.withLock {
            requestCount += 1
            if status == .notDetermined {
                status = grantsOnRequest ? .authorized : .denied
            }
            return status
        }
    }

    /// 사용자가 기기 설정에서 권한을 바꾼 상황을 흉내 냅니다.
    func simulateSystemChange(to newStatus: NotificationPermissionStatus) {
        lock.withLock { status = newStatus }
    }
}
