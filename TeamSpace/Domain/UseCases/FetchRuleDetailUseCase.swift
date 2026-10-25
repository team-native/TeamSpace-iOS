import Foundation

/// 09-2 규칙 상세 — 조항은 번호 순, 변경 내역은 최신순
struct FetchRuleDetailUseCase {
    private let ruleRepository: RuleRepository

    init(ruleRepository: RuleRepository) {
        self.ruleRepository = ruleRepository
    }

    func execute(id: Int) async throws -> RuleDetail {
        let detail = try await ruleRepository.fetchRuleDetail(id: id)
        return RuleDetail(
            rule: detail.rule,
            articles: detail.articles.sorted { $0.number < $1.number },
            acknowledgedAt: detail.acknowledgedAt,
            revisions: detail.revisions.sorted { $0.revisedAt > $1.revisedAt }
        )
    }
}
