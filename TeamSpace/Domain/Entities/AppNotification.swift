import Foundation

/// 서버 알림 유형 (`type`). 모르는 값은 `.unknown`.
/// TODO: 명세서 예시는 "APPROVAL" 하나뿐 — 전체 값 목록 백엔드 확인 필요
enum NotificationType: String, UnknownCaseDecodable {
    case approval = "APPROVAL"
    case approvalResult = "APPROVAL_RESULT"
    case finance = "FINANCE"
    case schedule = "SCHEDULE"
    case rule = "RULE"
    case notice = "NOTICE"
    /// 내 문의에 공식 답변 도착 (작성자 본인만 받음)
    case inquiryAnswer = "INQUIRY_ANSWER"
    case unknown = "UNKNOWN"

    static let unknownCase: NotificationType = .unknown
}

/// 알림 분류 — 알림 센터 필터 기준
enum NotificationCategory: CaseIterable, Hashable {
    case personalTask
    case finance
    case schedule
    case rule
    case notice
    case etc
}

extension NotificationType {
    var category: NotificationCategory {
        switch self {
        case .approval, .approvalResult, .inquiryAnswer: return .personalTask
        case .finance: return .finance
        case .schedule: return .schedule
        case .rule: return .rule
        case .notice: return .notice
        case .unknown: return .etc
        }
    }
}

struct AppNotification: Identifiable, Equatable {
    let id: Int
    let type: NotificationType
    let title: String
    /// 본문 — 명세서에 없는 필드라 서버가 주지 않으면 nil
    let message: String?
    /// 이동 경로 (예: "/approvals/12")
    let deepLink: String?
    var isRead: Bool
    let createdAt: Date
    /// 제도 · 규칙 알림의 시행일 (명세서에 없는 필드 — 서버와 맞춰야 함)
    var effectiveAt: Date? = nil
}
