import Foundation
import Observation

/// 13 통합 검색 분류 칩 — 공개 게시글과 운영 제안은 한 칩으로 묶어요.
enum SearchFilter: CaseIterable, Hashable {
    case all
    case documents
    case projects
    case people
    case posts

    var title: String {
        switch self {
        case .all: return "전체"
        case .documents: return "문서·규정"
        case .projects: return "프로젝트"
        case .people: return "팀원"
        case .posts: return "공개 글·제안"
        }
    }

    var categories: Set<SearchCategory> {
        switch self {
        case .all: return Set(SearchCategory.allCases)
        case .documents: return [.documents]
        case .projects: return [.projects]
        case .people: return [.people]
        case .posts: return [.posts, .proposals]
        }
    }
}

/// 13 결과 묶음 한 칸 — "문서·규정 · 2"
struct SearchSection: Identifiable, Equatable {
    let title: String
    let count: Int
    let hits: [SearchHit]

    var id: String { title }
}

/// 13 통합 검색
@Observable
@MainActor
final class IntegratedSearchViewModel {
    /// 입력을 멈추고 이만큼 지나면 검색해요.
    static let debounceNanoseconds: UInt64 = 300_000_000

    var query = ""
    var filter: SearchFilter = .all
    private(set) var state: ViewState<SearchResult> = .idle

    private let searchAllUseCase: SearchAllUseCase
    private let now: () -> Date

    init(searchAllUseCase: SearchAllUseCase, now: @escaping () -> Date = { Date() }) {
        self.searchAllUseCase = searchAllUseCase
        self.now = now
    }

    /// 1자만 입력했을 때 안내
    var isQueryTooShort: Bool {
        let count = query.trimmingCharacters(in: .whitespacesAndNewlines).count
        return count > 0 && count < SearchAllUseCase.minimumLength
    }

    var title: String {
        guard let result = state.value else { return "통합 검색" }
        return "\(result.query) 검색 결과"
    }

    func count(of filter: SearchFilter) -> Int {
        guard let result = state.value else { return 0 }
        return filter.categories.reduce(0) { $0 + (result.counts[$1] ?? 0) }
    }

    /// "총 6개 · 관련도순"
    var summaryText: String {
        "총 \(count(of: filter))개 · 관련도순"
    }

    /// "2026.10.16 기준"
    var baseDateText: String {
        "\(TSFormat.fullDate(now())) 기준"
    }

    /// 고른 칩 안에서 보여줄 묶음 — 결과가 없는 묶음은 빼요.
    var sections: [SearchSection] {
        guard let result = state.value else { return [] }
        let groups: [(String, Set<SearchCategory>)] = [
            ("문서·규정", [.documents]),
            ("프로젝트", [.projects]),
            ("팀원", [.people]),
            ("공개 게시글·운영 제안", [.posts, .proposals])
        ]
        return groups.compactMap { title, categories in
            let visible = categories.intersection(filter.categories)
            let hits = result.items.filter { visible.contains($0.category) }
            guard !hits.isEmpty else { return nil }
            let count = visible.reduce(0) { $0 + (result.counts[$1] ?? 0) }
            return SearchSection(title: title, count: max(count, hits.count), hits: hits)
        }
    }

    /// 칩을 골랐는데 그 분류 결과가 없는지
    var isFilteredEmpty: Bool {
        state.value != nil && sections.isEmpty
    }

    func search() async {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.count >= SearchAllUseCase.minimumLength else {
            state = .idle
            return
        }
        if state.value == nil { state = .loading }
        do {
            guard let result = try await searchAllUseCase.execute(query: keyword) else { return }
            guard !Task.isCancelled else { return }
            state = result.isEmpty ? .empty : .loaded(result)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.record(error, context: "search.all")
            state = .failed(error)
        }
    }

    func resetFilter() {
        filter = .all
    }

    func clearQuery() {
        query = ""
        filter = .all
        state = .idle
    }
}
