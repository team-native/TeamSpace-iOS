import Foundation

/// 07-12 내 활동 요약 숫자
struct ActivitySummary: Equatable, Sendable {
    let unreadNotificationCount: Int
    let submittedDocumentCount: Int
    let postCount: Int
    let inquiryCount: Int
}
