import Foundation
import Observation

/// 08-7 PM 지원자 검토
@Observable
@MainActor
final class ApplicantReviewViewModel {
    private(set) var state: ViewState<ApplicantBoard> = .idle
    var filter: ApplicationFilter = .all
    /// 결과를 적고 있는 지원자
    var selectedId: Int?
    var decision: ApplicantDecision = .accept
    var reason = ""
    private(set) var isSubmitting = false
    var errorMessage: String?
    /// 결과 등록 후 안내
    var doneMessage: String?

    private let projectId: Int
    private let fetchApplicantsUseCase: FetchApplicantsUseCase
    private let decideApplicantUseCase: DecideApplicantUseCase

    init(projectId: Int, fetchApplicantsUseCase: FetchApplicantsUseCase, decideApplicantUseCase: DecideApplicantUseCase) {
        self.projectId = projectId
        self.fetchApplicantsUseCase = fetchApplicantsUseCase
        self.decideApplicantUseCase = decideApplicantUseCase
    }

    var board: ApplicantBoard? { state.value }
    private var all: [Applicant] { board?.applicants ?? [] }

    var applicants: [Applicant] {
        guard let status = filter.status else { return all }
        return all.filter { $0.status == status }
    }

    var selected: Applicant? { all.first { $0.id == selectedId } }

    /// 칩 — 지원자가 있는 상태만
    var filters: [ApplicationFilter] {
        ApplicationFilter.allCases.filter { $0 == .all || count(of: $0) > 0 }
    }

    func count(of filter: ApplicationFilter) -> Int {
        guard let status = filter.status else { return all.count }
        return all.filter { $0.status == status }.count
    }

    /// "1명 · 확정 0명"
    var headcountText: String {
        "\(board?.opening.headcount ?? 0)명 · 확정 \(count(of: .accepted))명"
    }

    /// "접수 1 · 검토 중 2"
    var progressText: String {
        [ApplicationFilter.submitted, .reviewing, .accepted, .declined]
            .filter { count(of: $0) > 0 }
            .map { "\($0.title) \(count(of: $0))" }
            .joined(separator: " · ")
    }

    var canSubmit: Bool {
        !isSubmitting && selected?.status.isCancelable == true
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var submitTitle: String {
        decision == .accept ? "참여 확정 · 결과 등록" : "미선정 · 결과 등록"
    }

    func select(_ applicant: Applicant) {
        selectedId = applicant.id
        decision = .accept
        reason = applicant.resultReason ?? ""
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let board = try await fetchApplicantsUseCase.execute(projectId: projectId)
            state = .loaded(board)
            if selectedId == nil, let first = board.applicants.first(where: { $0.status.isCancelable }) {
                select(first)
            }
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.applicants.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func submit() async {
        guard var board = board, let applicant = selected, canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let updated = try await decideApplicantUseCase.execute(
                projectId: projectId, applicant: applicant, decision: decision, reason: reason
            )
            board.applicants = board.applicants.map { $0.id == updated.id ? updated : $0 }
            state = .loaded(board)
            doneMessage = "\(updated.name) 님에게 ‘\(updated.status.badgeTitle)’ 결과를 개인 업무 알림으로 보냈어요."
            selectedId = nil
            reason = ""
        } catch {
            AppLog.record(error, context: "project.applicants.decide")
            errorMessage = error.userMessage
        }
    }
}
