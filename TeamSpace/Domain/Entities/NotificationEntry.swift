import Foundation

/// 푸시 알림을 눌러 앱에 들어온 경우 — 로그인 후 돌아갈 곳 (02-8)
/// 인증 전에는 종류와 경로만 기억하고, 제목 · 금액 같은 내용은 보관하지 않아요.
struct NotificationEntry: Equatable, Sendable {
    let type: NotificationType
    let deepLink: String?

    /// 푸시 payload 의 `type` · `deepLink` 값으로 만듭니다. type 이 없으면 nil
    init?(type rawType: String?, deepLink: String?) {
        guard let rawType, !rawType.isEmpty else { return nil }
        self.type = NotificationType(rawValue: rawType) ?? .unknown
        self.deepLink = deepLink
    }
}
