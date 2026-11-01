import Foundation
import Observation

/// 07-5 임시 저장 문서
@Observable
@MainActor
final class DraftDocumentsViewModel {
    private(set) var state: ViewState<[MyDocument]> = .idle
    /// 삭제 확인을 기다리는 문서
    var pendingDelete: MyDocument?
    private(set) var isDeleting = false
    var errorMessage: String?

    private let fetchMyDocumentsUseCase: FetchMyDocumentsUseCase
    private let deleteDraftUseCase: DeleteDraftUseCase

    init(fetchMyDocumentsUseCase: FetchMyDocumentsUseCase, deleteDraftUseCase: DeleteDraftUseCase) {
        self.fetchMyDocumentsUseCase = fetchMyDocumentsUseCase
        self.deleteDraftUseCase = deleteDraftUseCase
    }

    var drafts: [MyDocument] {
        state.value ?? []
    }

    /// "마지막 동기화 10.16 09:38"
    var lastSyncText: String? {
        guard let latest = drafts.map(\.updatedAt).max() else { return nil }
        return "마지막 동기화 \(TSFormat.shortDate(latest)) \(TSFormat.time(latest))"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let drafts = try await fetchMyDocumentsUseCase.execute().filter(\.isDraft)
            state = drafts.isEmpty ? .empty : .loaded(drafts)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.drafts.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 확인 창에서 "삭제"
    func confirmDelete() async {
        guard let document = pendingDelete, !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await deleteDraftUseCase.execute(document)
            pendingDelete = nil
            let remaining = drafts.filter { $0.id != document.id }
            state = remaining.isEmpty ? .empty : .loaded(remaining)
        } catch {
            AppLog.record(error, context: "workspace.drafts.delete")
            pendingDelete = nil
            errorMessage = error.userMessage
        }
    }
}
