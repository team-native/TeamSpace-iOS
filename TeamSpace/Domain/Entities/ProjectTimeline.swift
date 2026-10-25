import Foundation

/// 마일스톤 진행 상태
enum MilestoneState: String, UnknownCaseDecodable, Sendable {
    case done = "DONE"
    case current = "CURRENT"
    case upcoming = "UPCOMING"
    case unknown = "UNKNOWN"

    static let unknownCase: MilestoneState = .unknown
}

struct ProjectMilestone: Equatable, Sendable {
    let title: String
    let date: Date
    /// 예) "내 참석 일정", "스토어 심사 자료 준비"
    let note: String?
    let state: MilestoneState
}

/// 이 프로젝트에서 내가 참석하는 일정
struct ProjectMySchedule: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let startsAt: Date
    let endsAt: Date
    let place: String
}

/// 일정 변경 이력 한 건 (최근 것이 위)
struct ProjectScheduleChange: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let changedAt: Date
    let editorName: String
    let editorRole: String
    let beforeStart: Date
    let beforeEnd: Date
    let afterStart: Date
    let afterEnd: Date
    let place: String
    let reason: String
    /// 알림을 만든 참여자 수
    let notifiedCount: Int
}

/// 08-8 프로젝트 일정과 변경 이력
struct ProjectTimeline: Equatable, Sendable {
    let projectName: String
    let status: ProjectRunStatus
    let isJoined: Bool
    let milestones: [ProjectMilestone]
    let mySchedules: [ProjectMySchedule]
    let changes: [ProjectScheduleChange]
}
