import Foundation

/// 프로젝트 등록 · 수정 입력 [Admin] (POST /admin/projects · PATCH /admin/projects/{id})
struct ProjectDraft: Equatable, Sendable {
    static let nameLimit = 40
    static let summaryLimit = 80

    var name = ""
    var summary = ""
    var department = Department.nativeOps.rawValue
    var pmName = ""
    var status: ProjectRunStatus = .planned
    var startDate: Date
    var endDate: Date
    var progress = 0

    /// 오늘부터 3개월로 시작해요.
    init(now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        startDate = today
        endDate = calendar.date(byAdding: .month, value: 3, to: today) ?? today
    }

    /// 수정 — 상세 내용으로 채워요. (기간이 없으면 오늘부터)
    init(editing project: ProjectSummary, now: Date = Date(), calendar: Calendar = .current) {
        self.init(now: now, calendar: calendar)
        name = project.name
        summary = project.summary
        department = project.department
        pmName = project.pmName
        status = project.status == .unknown ? .inProgress : project.status
        if let start = project.startDate { startDate = start }
        if let end = project.endDate { endDate = end }
        progress = min(max(project.progress, 0), 100)
    }
}
