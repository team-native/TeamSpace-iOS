import Foundation
import Observation

/// 04-9 프로젝트별 금액 · 04-8 권한 없음
@Observable
@MainActor
final class ProjectAmountsViewModel {
    /// 처음에 보여줄 프로젝트 수 (Figma: 4개 + "외 N개 프로젝트 보기")
    static let collapsedCount = 4

    private(set) var state: ViewState<ProjectAmountSummary> = .idle
    var filter: ProjectAmountFilter = .all
    var isExpanded = false

    let year: Int
    let user: AuthUser
    private let fetchProjectAmountsUseCase: FetchProjectAmountsUseCase

    init(year: Int, user: AuthUser, fetchProjectAmountsUseCase: FetchProjectAmountsUseCase) {
        self.year = year
        self.user = user
        self.fetchProjectAmountsUseCase = fetchProjectAmountsUseCase
    }

    /// 서버가 금액을 가렸거나, 내 권한으로 볼 수 없으면 04-8 화면
    var isAmountHidden: Bool {
        guard let summary = state.value else { return !user.can(.viewFinanceDetail) }
        return summary.isMasked || !user.can(.viewFinanceDetail)
    }

    private var filteredProjects: [ProjectAmount] {
        (state.value?.projects ?? []).filter { filter.matches($0) }
    }

    var visibleProjects: [ProjectAmount] {
        isExpanded || filter != .all ? filteredProjects : Array(filteredProjects.prefix(Self.collapsedCount))
    }

    var hiddenCount: Int {
        filteredProjects.count - visibleProjects.count
    }

    /// 누적 입금 비율 (0~100)
    var paidPercent: Int {
        guard
            let summary = state.value,
            let total = summary.totalContractAmount,
            let paid = summary.totalPaidAmount,
            total > 0
        else { return 0 }
        return Int((Double(paid) / Double(total) * 100).rounded())
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let result = try await fetchProjectAmountsUseCase.execute(year: year)
            state = result.projects.isEmpty ? .empty : .loaded(result)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.projects")
            if state.value == nil { state = .failed(error) }
        }
    }
}

/// 04-9 필터 — 전체 · 진행 중 · 완료
enum ProjectAmountFilter: Hashable, CaseIterable {
    case all
    case inProgress
    case completed

    var title: String {
        switch self {
        case .all: return "전체"
        case .inProgress: return "진행 중"
        case .completed: return "완료"
        }
    }

    func matches(_ project: ProjectAmount) -> Bool {
        switch self {
        case .all: return true
        case .inProgress: return project.status == .inProgress
        case .completed: return project.status == .completed
        }
    }
}

extension ProjectAmountStatus {
    var title: String {
        switch self {
        case .inProgress: return "진행 중"
        case .completed: return "완료"
        case .unknown: return "확인 필요"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .inProgress: return .primary
        case .completed: return .positive
        case .unknown: return .neutral
        }
    }
}
