import Foundation

/// 09-1 규칙 목록 — 읽지 않은 중요 개정 → 시행 예정 → 최근 개정 순
struct FetchRulesUseCase {
    private let ruleRepository: RuleRepository

    init(ruleRepository: RuleRepository) {
        self.ruleRepository = ruleRepository
    }

    func execute() async throws -> [RuleSummary] {
        try await ruleRepository.fetchRules().sorted { left, right in
            let leftUrgent = left.isImportant && !left.isAcknowledged
            let rightUrgent = right.isImportant && !right.isAcknowledged
            if leftUrgent != rightUrgent { return leftUrgent }
            if (left.status == .scheduled) != (right.status == .scheduled) { return left.status == .scheduled }
            return left.revisedAt > right.revisedAt
        }
    }
}
