import Foundation
import Observation

/// 알림을 눌러 들어온 목적지를 로그인 전후로 들고 있습니다. (02-8)
@Observable
@MainActor
final class NotificationEntryRouter {
    private(set) var pending: NotificationEntry?

    func receive(_ entry: NotificationEntry) {
        pending = entry
    }

    /// 목적지로 이동할 때 한 번만 꺼내 씁니다.
    func take() -> NotificationEntry? {
        defer { pending = nil }
        return pending
    }

    /// 02-8 "알림 진입 취소"
    func cancel() {
        pending = nil
    }
}
