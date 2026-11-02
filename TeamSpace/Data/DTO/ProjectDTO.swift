import Foundation

/// Mock 프로젝트 데이터 · GET /projects/{id}/schedule 응답 — 서버에 일정 API 가 없어 Figma 08 기준이에요. (백엔드와 맞춰야 함)
/// 목록 · 상세는 `ProjectServerDTO` 를 써요.
struct ProjectOpeningDTO: Codable {
    let id: Int
    let role: String
    let title: String
    let headcount: Int
    let startDate: Date
    let endDate: Date
    let description: String

    func toEntity() -> ProjectOpening {
        ProjectOpening(id: id, role: role, title: title, headcount: headcount, startDate: startDate, endDate: endDate, description: description)
    }
}

struct ProjectSummaryDTO: Codable {
    let id: String
    let name: String
    let summary: String
    let department: String
    let pmName: String
    let memberCount: Int
    let status: String
    let startDate: Date
    let endDate: Date
    let progress: Int
    let openings: [ProjectOpeningDTO]
    let resultNote: String?
    let updatedAt: Date

    func toEntity() -> ProjectSummary {
        ProjectSummary(
            id: id, name: name, summary: summary, department: department, pmName: pmName,
            memberCount: memberCount, status: ProjectRunStatus(rawValue: status) ?? .unknown,
            startDate: startDate, endDate: endDate, progress: progress,
            openings: openings.map { $0.toEntity() }, resultNote: resultNote, updatedAt: updatedAt
        )
    }
}

struct ProjectTimelineDTO: Codable {
    let projectName: String
    let status: String
    let isJoined: Bool
    let milestones: [MilestoneDTO]
    let mySchedules: [MyScheduleDTO]
    let changes: [ChangeDTO]

    struct MilestoneDTO: Codable {
        let title: String
        let date: Date
        let note: String?
        let state: String
    }

    struct MyScheduleDTO: Codable {
        let id: Int
        let title: String
        let startsAt: Date
        let endsAt: Date
        let place: String
    }

    struct ChangeDTO: Codable {
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
        let notifiedCount: Int
    }

    func toEntity() -> ProjectTimeline {
        ProjectTimeline(
            projectName: projectName,
            status: ProjectRunStatus(rawValue: status) ?? .unknown,
            isJoined: isJoined,
            milestones: milestones.map {
                ProjectMilestone(title: $0.title, date: $0.date, note: $0.note, state: MilestoneState(rawValue: $0.state) ?? .unknown)
            },
            mySchedules: mySchedules.map {
                ProjectMySchedule(id: $0.id, title: $0.title, startsAt: $0.startsAt, endsAt: $0.endsAt, place: $0.place)
            },
            changes: changes.map {
                ProjectScheduleChange(
                    id: $0.id, title: $0.title, changedAt: $0.changedAt, editorName: $0.editorName,
                    editorRole: $0.editorRole, beforeStart: $0.beforeStart, beforeEnd: $0.beforeEnd,
                    afterStart: $0.afterStart, afterEnd: $0.afterEnd, place: $0.place, reason: $0.reason,
                    notifiedCount: $0.notifiedCount
                )
            }
        )
    }
}
