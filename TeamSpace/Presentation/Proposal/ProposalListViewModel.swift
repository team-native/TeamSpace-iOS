import Foundation
import Observation

/// 12-1b 운영 제안 목록
@Observable
@MainActor
final class ProposalListViewModel {
    private(set) var state: ViewState<[ProposalSummary]> = .idle
    var sort: ProposalSort = .latest
    /// nil = 전체 단계
    var phase: ProposalPhase?
    /// nil = 부서 전체
    var department: String?
    /// nil = 상태 전체
    var status: ProposalStatus?

    private let fetchProposalsUseCase: FetchProposalsUseCase

    init(fetchProposalsUseCase: FetchProposalsUseCase) {
        self.fetchProposalsUseCase = fetchProposalsUseCase
    }

    private var all: [ProposalSummary] { state.value ?? [] }

    var proposals: [ProposalSummary] {
        let filtered = all.filter { proposal in
            (phase.map { $0.contains(proposal.status) } ?? true)
                && (department == nil || proposal.department == department)
                && (status == nil || proposal.status == status)
        }
        switch sort {
        case .latest: return filtered.sorted { $0.createdAt > $1.createdAt }
        case .recommended: return filtered.sorted { ($0.recommendCount, $0.createdAt) > ($1.recommendCount, $1.createdAt) }
        }
    }

    /// "부서 전체" 메뉴 — 목록에 있는 부서
    var departments: [String] {
        all.map(\.department).reduce(into: [String]()) { result, name in
            if !result.contains(name) { result.append(name) }
        }
    }

    /// "상태 전체" 메뉴 — 목록에 있는 상태
    var statuses: [ProposalStatus] {
        ProposalStatus.steps.filter { step in all.contains { $0.status == step } }
            + [.answered, .adopted, .closed, .rejected].filter { step in all.contains { $0.status == step } }
    }

    var departmentTitle: String { department ?? "부서 전체" }
    var statusTitle: String { status?.title ?? "상태 전체" }

    /// 진행중 · 완료 칩은 다시 누르면 꺼져요.
    func togglePhase(_ phase: ProposalPhase) {
        self.phase = self.phase == phase ? nil : phase
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchProposalsUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "proposal.list.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
