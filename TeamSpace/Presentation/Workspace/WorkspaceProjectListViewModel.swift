import Foundation
import Observation

/// 07-18 프로젝트 목록 상태 칩 — 모집 중인 프로젝트는 "모집 중"에만 들어가요.
enum WorkspaceProjectTab: CaseIterable, Hashable {
    case all
    case inProgress
    case recruiting
    case completed

    var title: String {
        switch self {
        case .all: return "전체"
        case .inProgress: return "진행 중"
        case .recruiting: return "모집 중"
        case .completed: return "완료"
        }
    }

    func matches(_ project: ProjectSummary) -> Bool {
        switch self {
        case .all: return true
        case .inProgress: return project.status == .inProgress && !project.isRecruiting
        case .recruiting: return project.isRecruiting
        case .completed: return project.status == .completed && !project.isRecruiting
        }
    }
}

/// 07-18 프로젝트 목록 (내 공간)
@Observable
@MainActor
final class WorkspaceProjectListViewModel {
    private(set) var state: ViewState<[ProjectSummary]> = .idle
    var tab: WorkspaceProjectTab = .all

    private let fetchProjectsUseCase: FetchProjectsUseCase
    private let now: () -> Date

    init(fetchProjectsUseCase: FetchProjectsUseCase, now: @escaping () -> Date = { Date() }) {
        self.fetchProjectsUseCase = fetchProjectsUseCase
        self.now = now
    }

    var projects: [ProjectSummary] {
        (state.value ?? []).filter(tab.matches)
    }

    func count(of tab: WorkspaceProjectTab) -> Int {
        (state.value ?? []).filter(tab.matches).count
    }

    /// "PM 이시우 · NativeLab · 2명 · 마감 11월 6일"
    func metaText(for project: ProjectSummary) -> String {
        project.listMetaText(now: now())
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let projects = try await fetchProjectsUseCase.execute()
            state = projects.isEmpty ? .empty : .loaded(projects)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.projectList.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}

extension ProjectSummary {
    /// 마감이 이만큼 남았을 때부터 카드에 "마감 ○월 ○일"을 붙여요.
    static let deadlineNoticeDays = 30

    /// 07-18 카드 한 줄 설명
    func listMetaText(now: Date, calendar: Calendar = .current) -> String {
        let pm = pmName.isEmpty ? "PM 모집" : "PM \(pmName)"
        var parts = [pm, department]
        if isRecruiting {
            parts.append("팀원 \(openings.reduce(0) { $0 + $1.headcount })명 모집")
            return parts.joined(separator: " · ")
        }
        parts.append("\(memberCount)명")
        switch status {
        case .completed:
            parts.append("\(TSFormat.monthDay(endDate)) 종료")
        case .inProgress:
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: endDate)).day ?? .max
            if (0...Self.deadlineNoticeDays).contains(days) {
                parts.append("마감 \(TSFormat.monthDay(endDate))")
            }
        default:
            break
        }
        return parts.joined(separator: " · ")
    }

    /// "디자인 1 · 개발 1 필요"
    var openingsNeedText: String {
        openings.map { "\($0.role) \($0.headcount)" }.joined(separator: " · ") + " 필요"
    }
}
