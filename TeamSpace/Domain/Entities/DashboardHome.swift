import Foundation

/// GET /dashboard/home — 02-1 홈 한 화면에 필요한 요약
struct DashboardHome: Equatable, Sendable {
    /// 오늘 확인할 일 (결재 대기 등)
    let todayTaskCount: Int
    let unreadNotificationCount: Int
    let latestNotification: DashboardNotificationPreview?
    /// 재정 권한이 없으면 nil
    let finance: FinanceSummary?
    let contracts: ContractSummary?
    let projects: [ProjectProgress]
    let schedules: [ScheduleItem]
    let notices: [NoticePreview]
}

struct DashboardNotificationPreview: Equatable, Sendable {
    let type: NotificationType
    let title: String
    let subtitle: String
    let createdAt: Date
}

/// 진행 중인 프로젝트
struct ProjectProgress: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let memberCount: Int
    let dueDate: Date
    /// 0~100
    let progress: Int
}

/// 주요 일정
struct ScheduleItem: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    /// 예) 온라인 · 내부 운영 플랫폼
    let place: String
    let startsAt: Date
}

enum NoticeCategory: String, UnknownCaseDecodable, Encodable, Hashable, Sendable {
    case finance = "FINANCE"
    case rule = "RULE"
    case notice = "NOTICE"
    case unknown = "UNKNOWN"

    static let unknownCase: NoticeCategory = .unknown
}

/// 지금 팀이 알아야 할 것들
struct NoticePreview: Equatable, Identifiable, Sendable {
    let id: Int
    let category: NoticeCategory
    let title: String
    let updatedAt: Date
}
