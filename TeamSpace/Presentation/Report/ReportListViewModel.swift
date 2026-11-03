import Foundation
import Observation

/// 신고 관리 [Admin] — GET /admin/reports · POST /admin/reports/{id}/decision
@Observable
@MainActor
final class ReportListViewModel {
    enum Filter: CaseIterable, Hashable {
        case pending
        case all

        var title: String { self == .pending ? "대기 중" : "전체" }
    }

    private(set) var state: ViewState<[PostReportItem]> = .idle
    private(set) var filter: Filter = .pending
    private(set) var processingId: Int?
    /// 처리 방법을 고르는 중인 신고
    var decidingReport: PostReportItem?
    var toastMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let fetchReportsUseCase: FetchReportsUseCase
    private let decideReportUseCase: DecideReportUseCase

    init(user: AuthUser, fetchReportsUseCase: FetchReportsUseCase, decideReportUseCase: DecideReportUseCase) {
        self.user = user
        self.fetchReportsUseCase = fetchReportsUseCase
        self.decideReportUseCase = decideReportUseCase
    }

    var reports: [PostReportItem] { state.value ?? [] }

    var pendingCountText: String {
        "대기 중 \(reports.filter { $0.status == .pending }.count)건"
    }

    func select(_ filter: Filter) async {
        guard filter != self.filter else { return }
        self.filter = filter
        state = .loading
        await load()
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let items = try await fetchReportsUseCase.execute(user: user, pendingOnly: filter == .pending)
            state = items.isEmpty ? .empty : .loaded(items)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "report.list.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func decide(_ decision: ReportDecision) async {
        guard let report = decidingReport, processingId == nil else { return }
        decidingReport = nil
        processingId = report.id
        defer { processingId = nil }
        do {
            let updated = try await decideReportUseCase.execute(report, decision: decision, user: user)
            var items = reports
            if filter == .pending {
                items.removeAll { $0.id == report.id }
            } else if let index = items.firstIndex(where: { $0.id == report.id }) {
                items[index] = updated
            }
            state = items.isEmpty ? .empty : .loaded(items)
            switch decision {
            case .hide: toastMessage = "글을 숨겼어요"
            case .delete: toastMessage = "글을 삭제했어요"
            case .reject: toastMessage = "신고를 반려했어요"
            }
        } catch {
            AppLog.record(error, context: "report.decide")
            errorMessage = error.userMessage
        }
    }
}

extension PostReportItem {
    /// 글 제목이 없으면 숨김 · 삭제된 글이에요.
    var titleText: String { postTitle ?? "볼 수 없는 글 · #\(postId)" }

    var detailText: String { detail.isEmpty ? "추가 설명 없음" : detail }

    /// "숨김 · 관리자 · 11.03"
    var handledText: String? {
        guard status != .pending else { return nil }
        return [status.title, handledBy, handledAt.map(TSFormat.shortDate)].compactMap { $0 }.joined(separator: " · ")
    }
}
