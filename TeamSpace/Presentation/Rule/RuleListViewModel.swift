import Foundation
import Observation

/// 09-1 규칙 · 제도 목록
@Observable
@MainActor
final class RuleListViewModel {
    private(set) var state: ViewState<[RuleSummary]> = .idle
    var query = ""
    /// nil = 전체 분류
    var category: RuleCategory?
    var statusFilter: RuleStatusFilter = .all

    private let fetchRulesUseCase: FetchRulesUseCase
    private let now: () -> Date

    init(fetchRulesUseCase: FetchRulesUseCase, now: @escaping () -> Date = { Date() }) {
        self.fetchRulesUseCase = fetchRulesUseCase
        self.now = now
    }

    private var all: [RuleSummary] { state.value ?? [] }

    /// 맨 위 "시행 전 꼭 읽어주세요" — 읽음 확인 안 한 중요 개정
    var urgentRule: RuleSummary? {
        all.first { $0.isImportant && !$0.isAcknowledged }
    }

    var rules: [RuleSummary] {
        all.filter { rule in
            (category == nil || rule.category == category)
                && statusFilter.matches(rule, now: now())
                && rule.matches(query)
        }
    }

    func linkTitle(for rule: RuleSummary) -> String {
        rule.linkTitle(now: now())
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchRulesUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "rule.list.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
