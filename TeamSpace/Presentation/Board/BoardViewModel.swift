import Foundation
import Observation

/// 10-1 팀 게시판
@Observable
@MainActor
final class BoardViewModel {
    /// 인기글 개수
    static let popularLimit = 3

    private(set) var state: ViewState<Board> = .idle
    var period: BoardPeriod = .week
    var filter: BoardFilter = .all
    var sort: BoardSort = .latest

    private let fetchBoardUseCase: FetchBoardUseCase
    private let now: () -> Date

    init(fetchBoardUseCase: FetchBoardUseCase, now: @escaping () -> Date = { Date() }) {
        self.fetchBoardUseCase = fetchBoardUseCase
        self.now = now
    }

    var board: Board? { state.value }

    /// "고정 공지" — 전체 · 공지 칩에서만 보여요.
    var pinnedNotices: [NoticeSummary] {
        guard filter == .all || filter == .notice else { return [] }
        return board?.pinnedNotices ?? []
    }

    /// 기간 · 분류 · 정렬을 적용한 게시글
    var posts: [PostSummary] {
        let date = now()
        let filtered = (board?.posts ?? []).filter { period.contains($0.createdAt, now: date) && filter.matches($0) }
        switch sort {
        case .latest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .popular:
            return filtered.sorted { ($0.likeCount, $0.createdAt) > ($1.likeCount, $1.createdAt) }
        }
    }

    /// "이번 주 인기글" — 최근 7일 추천 많은 순
    var popularPosts: [PostSummary] {
        let date = now()
        return (board?.posts ?? [])
            .filter { BoardPeriod.week.contains($0.createdAt, now: date) }
            .sorted { ($0.likeCount, $0.createdAt) > ($1.likeCount, $1.createdAt) }
            .prefix(Self.popularLimit)
            .map { $0 }
    }

    /// "10.12 – 10.18"
    var popularRangeText: String {
        let today = Calendar.current.startOfDay(for: now())
        return "\(TSFormat.shortDate(today.addingTimeInterval(-6 * 86_400))) – \(TSFormat.shortDate(today))"
    }

    var inquiryCount: Int { board?.myRecord.inquiries.count ?? 0 }

    var emptyMessage: String? {
        guard filter != .notice, posts.isEmpty else { return nil }
        return "\(period.title) 올라온 \(filter == .all ? "" : filter.title + " ")글이 없어요. 기간을 바꿔 보세요."
    }

    func selectPeriod(_ period: BoardPeriod) {
        self.period = period
    }

    /// "인기글 더 보기" — 이번 주 인기순으로 다시 정렬해요.
    func showPopular() {
        period = .week
        filter = .all
        sort = .popular
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchBoardUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "board.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
