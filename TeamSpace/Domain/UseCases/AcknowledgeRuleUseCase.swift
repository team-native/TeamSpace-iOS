import Foundation

/// 09-2 읽음 확인 — 이미 확인했으면 서버에 다시 보내지 않아요.
struct AcknowledgeRuleUseCase {
    private let ruleRepository: RuleRepository

    init(ruleRepository: RuleRepository) {
        self.ruleRepository = ruleRepository
    }

    func execute(_ detail: RuleDetail) async throws -> RuleDetail {
        guard detail.acknowledgedAt == nil else { return detail }
        var updated = detail
        updated.acknowledgedAt = try await ruleRepository.acknowledge(ruleId: detail.rule.id)
        updated.rule.isAcknowledged = true
        return updated
    }
}
