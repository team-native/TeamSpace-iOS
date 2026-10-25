import Foundation
import Observation

/// 07-4 내가 제출한 문서
@Observable
@MainActor
final class MyDocumentsViewModel {
    private(set) var state: ViewState<[MyDocument]> = .idle
    var query = ""
    /// nil = 전체
    var statusFilter: ApprovalStatus?
    /// nil = 유형 전체
    var kindFilter: ApprovalKind?

    private let fetchMyDocumentsUseCase: FetchMyDocumentsUseCase

    init(fetchMyDocumentsUseCase: FetchMyDocumentsUseCase) {
        self.fetchMyDocumentsUseCase = fetchMyDocumentsUseCase
    }

    /// 상태 칩 — 전체 · 작성 중 · 결재 대기 · 검토 중 · 승인 · 반려
    let statusFilters: [ApprovalStatus?] = [nil, .draft, .pending, .reviewing, .approved, .rejected]

    /// 유형 칩 — 내 문서에 있는 종류만
    var kindFilters: [ApprovalKind?] {
        var seen: [ApprovalKind] = []
        for document in state.value ?? [] where !seen.contains(document.kind) {
            seen.append(document.kind)
        }
        return [nil] + seen
    }

    var documents: [MyDocument] {
        (state.value ?? []).filter { document in
            (statusFilter == nil || document.status == statusFilter)
                && (kindFilter == nil || document.kind == kindFilter)
                && document.matches(query)
        }
    }

    func statusTitle(_ status: ApprovalStatus?) -> String {
        status?.badgeTitle ?? "전체"
    }

    func kindTitle(_ kind: ApprovalKind?) -> String {
        kind?.documentTitle ?? "유형 전체"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchMyDocumentsUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.documents.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
