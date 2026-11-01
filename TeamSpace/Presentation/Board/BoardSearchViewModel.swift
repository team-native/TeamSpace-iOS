import Foundation
import Observation

/// 10-12 게시글 검색
@Observable
@MainActor
final class BoardSearchViewModel {
    /// 입력을 멈추고 이만큼 지나면 검색해요.
    static let debounceNanoseconds: UInt64 = 300_000_000

    var query = ""
    private(set) var state: ViewState<BoardSearchResult> = .idle
    private(set) var recentKeywords: [String] = []
    /// 결과가 어떤 검색어로 나온 것인지
    private(set) var searchedKeyword = ""

    private let searchBoardUseCase: SearchBoardUseCase
    private let recentSearchUseCase: RecentSearchUseCase

    init(searchBoardUseCase: SearchBoardUseCase, recentSearchUseCase: RecentSearchUseCase) {
        self.searchBoardUseCase = searchBoardUseCase
        self.recentSearchUseCase = recentSearchUseCase
        self.recentKeywords = recentSearchUseCase.fetch()
    }

    var result: BoardSearchResult { state.value ?? .empty }

    /// "정산 검색 결과 4건"
    var resultTitle: String {
        "\(searchedKeyword) 검색 결과 \(result.count)건"
    }

    var emptyMessage: String {
        "‘\(searchedKeyword)’에 맞는 글이 없어요. 다른 검색어로 찾아보세요."
    }

    /// 검색어가 비어 있으면 최근 검색어를 보여줘요.
    var showsRecent: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !recentKeywords.isEmpty
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
            let result = try await searchBoardUseCase.execute(keyword: keyword)
            guard !Task.isCancelled else { return }
            searchedKeyword = keyword
            state = result.isEmpty ? .empty : .loaded(result)
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.record(error, context: "board.search")
            state = .failed(error)
        }
    }

    /// 키보드의 검색 버튼
    func submit() {
        recentKeywords = recentSearchUseCase.record(query)
    }

    func selectRecent(_ keyword: String) {
        query = keyword
        recentKeywords = recentSearchUseCase.record(keyword)
    }

    func removeRecent(_ keyword: String) {
        recentKeywords = recentSearchUseCase.remove(keyword)
    }

    func clearRecent() {
        recentSearchUseCase.clear()
        recentKeywords = []
    }

    /// 결과를 열면 그 검색어를 기억해요.
    func didOpenResult() {
        recentKeywords = recentSearchUseCase.record(searchedKeyword)
    }
}
