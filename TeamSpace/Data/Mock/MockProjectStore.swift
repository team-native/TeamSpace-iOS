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

    // MARK: 08-3 ~ 08-7 모집 · 참여

    private var applications: [ApplicationDTO] = []
    private var applicants: [Int: [ApplicantDTO]] = [:]
    private var nextApplicationId = 200

    private func later(_ days: Double) -> Date { now.addingTimeInterval(days * 86_400) }

    /// 08-6 · 08-7 예시 — 처음 한 번만 만들어요.
    private func seedApplicationsIfNeeded() {
        guard applications.isEmpty else { return }
        func app(
            _ id: Int, _ projectId: Int, _ name: String, _ role: String, _ department: String, _ status: ApplicationStatus,
            applied: Double, pm: String, message: String, portfolio: String? = nil, reviewed: Double? = nil,
            due: Double? = nil, decided: Double? = nil, reason: String? = nil
        ) -> ApplicationDTO {
            ApplicationDTO(
                id: id, projectId: projectId, projectName: name, role: role, department: department, status: status,
                appliedAt: ago(applied), headcount: 1, pmName: pm, message: message, portfolioUrl: portfolio,
                reviewedAt: reviewed.map(ago), resultDueDate: due.map(later), decidedAt: decided.map(ago), resultReason: reason
            )
        }
        applications = [
            app(101, 6, "토벌 보수 앱", "iOS 개발", "NativeLab", .reviewing, applied: 3, pm: "이시우",
                message: "SwiftUI로 토벌 기록 앱을 만들어 봤어요. 위젯 개발과 QA에 참여하고 싶습니다. 주 6시간, 11월부터 참여 가능해요.",
                portfolio: "github.com/chiikawatodal-demo/capybara", reviewed: 2, due: 2),
            app(102, 2, "BRIDGE", "디자인", "NativeLab", .submitted, applied: 1, pm: "안율",
                message: "프로토타입 화면 디자인을 함께하고 싶어요."),
            app(103, 3, "Native 팀스페이스", "QA", "NativeOps", .accepted, applied: 28, pm: "양지우",
                message: "QA 체크리스트 작성과 실기기 테스트를 맡고 싶어요.", decided: 24, reason: "QA 경험이 역할에 잘 맞아요."),
            app(104, 5, "Inspace 리서치", "인터뷰", "Design", .declined, applied: 67, pm: "오잉",
                message: "사용자 인터뷰 진행을 돕고 싶어요.", decided: 60, reason: "이번 모집은 인원이 마감됐어요.")
        ]
        let message = "SwiftUI로 토벌 기록 앱을 만들어 봤어요. 위젯 개발과 QA에 참여하고 싶습니다. 주 6시간, 11월부터 참여 가능해요."
        applicants[1] = [
            ApplicantDTO(id: 1, name: "옥물결", role: "iOS 개발", status: .reviewing, appliedAt: ago(3), availability: .tenHours,
                         message: message, portfolioUrl: "https://github.com/chiikawatodal-demo/capybara", resultReason: nil),
            ApplicantDTO(id: 2, name: "오잉", role: "iOS 개발", status: .reviewing, appliedAt: ago(2), availability: .tenHours,
                         message: "SwiftUI 화면 개발과 실기기 QA 경험", portfolioUrl: nil, resultReason: nil),
            ApplicantDTO(id: 3, name: "잉오", role: "iOS 개발", status: .submitted, appliedAt: ago(1), availability: .twentyHours,
                         message: "위젯을 꼭 만들어 보고 싶어요.", portfolioUrl: nil, resultReason: nil)
        ]
    }

    /// GET /projects/{id}/recruitment — 모집 중인 자리가 없으면 nil
    func recruitmentJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        guard let project = projects.first(where: { $0.id == id }), let opening = project.openings.first else { return nil }
        let isBookOn = id == 1
        let mine = applications.first { $0.projectId == id && $0.status != .canceled }
        return envelope(RecruitmentDTO(
            projectId: id,
            projectName: project.name,
            opening: opening,
            headline: isBookOn ? "Book-on의 다음 기능을\n함께 만들어요" : "\(project.name)를\n함께 만들어요",
            introduction: isBookOn
                ? "독서 기록과 습관 만들기를 돕는 iOS 앱에서 위젯 개발과 출시 전 QA를 함께할 동료를 찾아요."
                : "\(project.summary)에 함께할 동료를 찾아요.",
            activityPeriod: isBookOn ? "11–12월 · 출시 후 안정화 포함" : "11–12월",
            activityHours: "주 6시간 내외 · 협의 가능",
            recruitStart: ago(10),
            recruitEnd: later(3),
            department: project.department,
            duties: isBookOn
                ? ["독서 목표와 기록을 보여주는 위젯 개발", "SwiftUI 화면의 접근성·상태 처리 개선", "실기기 QA와 출시 후 오류 수정"]
                : ["온보딩 문서 구조 정리", "신규 구성원 인터뷰 정리"],
            requirements: isBookOn
                ? "Swift·SwiftUI로 화면을 구현해 본 분, Git으로 협업 가능한 분을 찾아요. WidgetKit 경험이 있으면 좋아요."
                : "문서를 읽기 쉽게 다듬는 것을 좋아하는 분을 찾아요.",
            applyTip: "지원 시 작업물 링크와 참여 가능한 시간을 알려주세요. 학습 경험도 충분한 소개가 될 수 있어요.",
            pmName: project.pmName,
            documentTitle: "\(project.name) 킥오프 문서",
            isJoined: joinedIds.contains(id),
            myApplicationStatus: mine?.status
        ))
    }

    /// POST /projects/{id}/apply — (상태 코드, 응답)
    func apply(projectId: Int, request: ApplyRequestDTO) -> (Int, String) {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        guard let project = projects.first(where: { $0.id == projectId }),
              let opening = project.openings.first(where: { $0.id == request.openingId }) else {
            return (404, #"{"code":404,"message":"모집 중인 자리를 찾을 수 없습니다."}"#)
        }
        if joinedIds.contains(projectId) {
            return (409, #"{"code":409,"message":"이미 참여 중인 프로젝트예요."}"#)
        }
        if applications.contains(where: { $0.projectId == projectId && $0.status != .canceled }) {
            return (409, #"{"code":409,"message":"이미 신청한 자리예요. 내 참여 신청에서 확인해 주세요."}"#)
        }
        nextApplicationId += 1
        let application = ApplicationDTO(
            id: nextApplicationId, projectId: projectId, projectName: project.name, role: opening.title,
            department: project.department, status: .submitted, appliedAt: now, headcount: opening.headcount,
            pmName: project.pmName, message: request.message, portfolioUrl: nil, reviewedAt: nil,
            resultDueDate: later(5), decidedAt: nil, resultReason: nil
        )
        applications.append(application)
        applicants[projectId, default: []].append(ApplicantDTO(
            id: nextApplicationId, name: "홍길동", role: opening.title, status: .submitted, appliedAt: now,
            availability: Availability(rawValue: request.availability) ?? .tenHours, message: request.message,
            portfolioUrl: nil, resultReason: nil
        ))
        return (201, envelope(application))
    }

    func myApplicationsJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        return envelope(ApplicationListResponseDTO(list: applications))
    }

    func cancelApplication(id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        guard let index = applications.firstIndex(where: { $0.id == id }), applications[index].status.isCancelable else {
            return false
        }
        applications[index].status = .canceled
        return true
    }

    func applicantsJSON(projectId: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        guard let project = projects.first(where: { $0.id == projectId }), let opening = project.openings.first else { return nil }
        return envelope(ApplicantBoardDTO(
            projectName: project.name, pmName: project.pmName, opening: opening, recruitStart: ago(10),
            recruitEnd: later(3), resultDueDate: later(5), applicants: applicants[projectId, default: []]
        ))
    }

    func decide(projectId: Int, applicantId: Int, request: ApplicantDecisionRequestDTO) -> String? {
        lock.lock()
        defer { lock.unlock() }
        seedApplicationsIfNeeded()
        guard var list = applicants[projectId], let index = list.firstIndex(where: { $0.id == applicantId }) else { return nil }
        list[index].status = request.decision == "ACCEPT" ? .accepted : .declined
        list[index].resultReason = request.reason
        applicants[projectId] = list
        return envelope(list[index])
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
