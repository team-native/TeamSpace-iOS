import Foundation
import Observation

/// 06-2 문서 검색
@Observable
@MainActor
final class LibrarySearchViewModel {
    /// 입력을 멈추고 이만큼 지나면 검색해요.
    static let debounceNanoseconds: UInt64 = 300_000_000

    var query = ""
    private(set) var state: ViewState<[LibraryDocument]> = .idle
    private(set) var recentKeywords: [String] = []
    /// 결과가 어떤 검색어로 나온 것인지 (입력 중에도 이전 결과 문구가 흔들리지 않게)
    private(set) var searchedKeyword = ""

    private let searchLibraryUseCase: SearchLibraryUseCase
    private let recentSearchUseCase: RecentSearchUseCase

    init(searchLibraryUseCase: SearchLibraryUseCase, recentSearchUseCase: RecentSearchUseCase) {
        self.searchLibraryUseCase = searchLibraryUseCase
        self.recentSearchUseCase = recentSearchUseCase
        self.recentKeywords = recentSearchUseCase.fetch()
    }

    var results: [LibraryDocument] {
        state.value ?? []
    }

    /// "검색 결과 3"
    var resultTitle: String {
        "검색 결과 \(results.count)"
    }

    var emptyMessage: String {
        "‘\(searchedKeyword)’에 맞는 문서가 없어요. 다른 검색어로 찾아보세요."
    }

    func search() async {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            searchedKeyword = ""
            state = .idle
            return
        }
        if state.value == nil { state = .loading }
        do {
            let documents = try await searchLibraryUseCase.execute(keyword: keyword)
            guard !Task.isCancelled else { return }
            searchedKeyword = keyword
            state = documents.isEmpty ? .empty : .loaded(documents)
        } catch {
            // 입력이 바뀌어 취소된 검색은 무시해요.
            guard !Task.isCancelled else { return }
            AppLog.record(error, context: "library.search")
            state = .failed(error)
        }
    }

    /// 키보드의 검색 버튼
    func submit() {
        recentKeywords = recentSearchUseCase.record(query)
    }

    /// 최근 검색어 칩 — 검색창에 넣으면 `.task(id: query)` 가 검색해요.
    func selectRecent(_ keyword: String) {
        query = keyword
        recentKeywords = recentSearchUseCase.record(keyword)
    }

    /// 결과를 열면 그 검색어를 기억해요.
    func didOpenResult() {
        recentKeywords = recentSearchUseCase.record(searchedKeyword)
    }
}
