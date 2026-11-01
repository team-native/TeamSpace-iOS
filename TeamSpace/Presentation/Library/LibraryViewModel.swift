import Foundation
import Observation

/// 06-1 문서함 (문서함 탭 첫 화면)
@Observable
@MainActor
final class LibraryViewModel {
    private(set) var state: ViewState<LibraryOverview> = .idle
    var filter: LibraryFilter = .all

    private let fetchLibraryUseCase: FetchLibraryUseCase

    init(fetchLibraryUseCase: FetchLibraryUseCase) {
        self.fetchLibraryUseCase = fetchLibraryUseCase
    }

    private var documents: [LibraryDocument] {
        state.value?.documents ?? []
    }

    var latestRevision: LibraryRevision? {
        state.value?.latestRevision
    }

    /// 분류 카드의 문서 수
    func count(of filter: LibraryFilter) -> Int {
        guard let category = filter.category else { return documents.count }
        return documents.filter { $0.category == category }.count
    }

    /// 고른 분류의 문서 (최근 수정 순)
    var filteredDocuments: [LibraryDocument] {
        guard let category = filter.category else { return documents }
        return documents.filter { $0.category == category }
    }

    /// "12개의 문서"
    var countText: String {
        "\(filteredDocuments.count)개의 문서"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchLibraryUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "library.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
