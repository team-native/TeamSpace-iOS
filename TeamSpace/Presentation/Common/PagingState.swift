import Foundation

/// COMMON-02 목록 아래 "다음 페이지" 상태 — 커서 · 불러오는 중 · 실패
struct PagingState: Equatable {
    private(set) var nextCursor: String?
    private(set) var isLoading = false
    private(set) var didFail = false

    init(nextCursor: String? = nil) {
        self.nextCursor = nextCursor
    }

    var hasMore: Bool { nextCursor != nil }

    /// 다음 페이지를 부를 수 있으면 커서를 돌려주고 "불러오는 중"으로 바꿔요.
    mutating func begin() -> String? {
        guard let cursor = nextCursor, !isLoading else { return nil }
        isLoading = true
        didFail = false
        return cursor
    }

    mutating func finish(nextCursor: String?) {
        self.nextCursor = nextCursor
        isLoading = false
        didFail = false
    }

    /// 커서는 그대로 두고 실패만 표시해요 — 다시 불러오기로 같은 페이지를 다시 물어봐요.
    mutating func fail() {
        isLoading = false
        didFail = true
    }
}

extension Array where Element: Identifiable {
    /// 다음 페이지를 붙일 때 이미 있는 항목(중간에 새 글이 생겨 밀려온 것)은 빼요.
    func appendingUnique(_ newItems: [Element]) -> [Element] {
        let existing = Set(map(\.id))
        return self + newItems.filter { !existing.contains($0.id) }
    }
}
