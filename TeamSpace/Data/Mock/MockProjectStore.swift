import Foundation

/// Mock 프로젝트 — Figma 08 예시 (날짜는 올해 기준)
/// 프로젝트 1 · 3 은 07-6 참여 프로젝트와 같아요.
final class MockProjectStore: @unchecked Sendable {
    private let lock = NSLock()
    private let calendar: Calendar
    private let now: Date
    private var projects: [ProjectSummaryDTO] = []
    private let joinedIds: Set<Int> = [1, 3]

    init(now: Date = Date(), calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
        projects = makeProjects()
    }

    /// 올해의 월 · 일 (시간 포함)
    private func day(_ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = calendar.component(.year, from: now)
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? now
    }

    private func ago(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

    private func makeProjects() -> [ProjectSummaryDTO] {
        func project(
            _ id: Int, _ name: String, _ summary: String, _ department: String, pm: String, people: Int,
            _ status: String, from: Date, to: Date, progress: Int, openings: [ProjectOpeningDTO] = [],
            result: String? = nil, updated: Double
        ) -> ProjectSummaryDTO {
            ProjectSummaryDTO(
                id: id, name: name, summary: summary, department: department, pmName: pm, memberCount: people,
                status: status, startDate: from, endDate: to, progress: progress, openings: openings,
                resultNote: result, updatedAt: ago(updated)
            )
        }
        return [
            project(1, "Book-on", "독서 기록과 습관 만들기를 돕는 iOS 앱", "NativeLab", pm: "이시우", people: 6,
                    "IN_PROGRESS", from: day(7, 1), to: day(11, 30), progress: 68,
                    openings: [ProjectOpeningDTO(id: 11, role: "iOS", title: "iOS 개발", headcount: 1, startDate: day(11, 1),
                                                 endDate: day(12, 31), description: "위젯 기능 개발과 출시 전 QA를 함께해요.")],
                    updated: 0.1),
            project(2, "BRIDGE", "iOS 앱 프로토타입 제작", "NativeLab", pm: "안율", people: 4,
                    "IN_PROGRESS", from: day(9, 1), to: day(10, 31), progress: 80, updated: 1),
            project(3, "Native 팀스페이스", "내부 운영 플랫폼", "NativeOps", pm: "양지우", people: 8,
                    "IN_PROGRESS", from: day(7, 13), to: day(12, 4), progress: 55, updated: 2),
            project(4, "Native 팀 가이드", "신규 구성원 온보딩 가이드 개선", "NativeOps", pm: "양지우", people: 3,
                    "PLANNED", from: day(11, 1), to: day(12, 15), progress: 0,
                    openings: [ProjectOpeningDTO(id: 41, role: "에디터", title: "가이드 에디터", headcount: 1, startDate: day(11, 1),
                                                 endDate: day(12, 15), description: "온보딩 문서를 함께 다듬고 정리해요.")],
                    updated: 3),
            project(5, "Inspace 리서치", "팀 협업 경험 리서치와 제안", "Design", pm: "오잉", people: 5,
                    "COMPLETED", from: day(6, 1), to: day(9, 30), progress: 100, result: "회고 문서 공개", updated: 5)
        ]
    }

    // MARK: 응답

    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(ProjectListResponseDTO(list: projects))
    }

    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let project = projects.first(where: { $0.id == id }) else { return nil }
        return envelope(ProjectDetailDTO(
            project: project,
            members: members(for: project),
            relatedItems: [
                .init(id: 1, kind: "DOCUMENT", title: "\(project.name) 킥오프 문서", date: nil),
                .init(id: 2, kind: "SCHEDULE", title: "\(project.name) 디자인 리뷰", date: day(10, 14, 15))
            ],
            isJoined: joinedIds.contains(id)
        ))
    }

    func timelineJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let project = projects.first(where: { $0.id == id }) else { return nil }
        let isBookOn = id == 1
        let milestones: [ProjectTimelineDTO.MilestoneDTO] = isBookOn ? [
            .init(title: "핵심 기능 구현 완료", date: day(10, 9), note: "완료", state: "DONE"),
            .init(title: "위젯·QA 점검", date: day(10, 23, 15), note: "내 참석 일정", state: "CURRENT"),
            .init(title: "출시 준비", date: day(11, 16), note: "스토어 심사 자료 준비", state: "UPCOMING"),
            .init(title: "출시", date: day(11, 30), note: "예정", state: "UPCOMING")
        ] : [
            .init(title: "시작", date: project.startDate, note: nil, state: "DONE"),
            .init(title: "마무리", date: project.endDate, note: "예정", state: "UPCOMING")
        ]
        let changes: [ProjectTimelineDTO.ChangeDTO] = isBookOn ? [
            .init(id: 2, title: "QA 점검 일정이 변경됐어요", changedAt: day(10, 15, 14, 20), editorName: "이시우", editorRole: "PM",
                  beforeStart: day(10, 22, 14), beforeEnd: day(10, 22, 15), afterStart: day(10, 23, 15), afterEnd: day(10, 23, 16),
                  place: "온라인 · 기존 회의 링크 유지",
                  reason: "실기기 QA 결과를 먼저 반영하기 위해 점검을 하루 늦춰요. 참석이 어려우면 PM에게 알려주세요.",
                  notifiedCount: 6),
            .init(id: 1, title: "디자인 리뷰 시간 변경", changedAt: day(10, 12, 11), editorName: "오잉", editorRole: "Design",
                  beforeStart: day(10, 14, 14), beforeEnd: day(10, 14, 15), afterStart: day(10, 14, 15), afterEnd: day(10, 14, 16),
                  place: "온라인", reason: "논의 자료 보완", notifiedCount: 6)
        ] : []
        let schedules: [ProjectTimelineDTO.MyScheduleDTO] = isBookOn && joinedIds.contains(id) ? [
            .init(id: 1, title: "Book-on QA 점검", startsAt: day(10, 23, 15), endsAt: day(10, 23, 16), place: "온라인"),
            .init(id: 3, title: "Book-on 디자인 리뷰", startsAt: day(10, 14, 15), endsAt: day(10, 14, 16), place: "온라인")
        ] : []
        return envelope(ProjectTimelineDTO(
            projectName: project.name, status: project.status, isJoined: joinedIds.contains(id),
            milestones: milestones, mySchedules: schedules, changes: changes
        ))
    }

    private func members(for project: ProjectSummaryDTO) -> [ProjectDetailDTO.MemberDTO] {
        let people: [(String, String)] = [
            (project.pmName, "PM"), ("오잉", "Design"), ("잉오", "iOS"), ("오이무침", "Web"),
            ("옥물결", "Design"), ("김민규", "iOS"), ("이채율", "Web"), ("안율", "QA")
        ]
        var seen: Set<String> = []
        let unique = people.filter { seen.insert($0.0).inserted }
        return unique.prefix(project.memberCount).enumerated().map { index, person in
            ProjectDetailDTO.MemberDTO(id: index + 1, name: person.0, role: person.1)
        }
    }

    private func envelope<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"조회 성공","data":\#(data)}"#
    }
}
