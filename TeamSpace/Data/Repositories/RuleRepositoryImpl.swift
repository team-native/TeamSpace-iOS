import Foundation

final class RuleRepositoryImpl: RuleRepository, @unchecked Sendable {
    private let loader: DocPageLoader
    private let acknowledgements: RuleAcknowledgementStore

    init(client: APIClient, acknowledgements: RuleAcknowledgementStore = RuleAcknowledgementStore()) {
        self.loader = DocPageLoader(client: client)
        self.acknowledgements = acknowledgements
    }

    func fetchRules() async throws -> [RuleSummary] {
        try await loader.fetchDocs()
            .filter(\.isRule)
            .map { $0.toRuleSummary(isAcknowledged: acknowledgements.acknowledgedAt($0.slug) != nil) }
    }

    /// 개정 이력은 없어도 본문은 보여줘요.
    func fetchRuleDetail(id: String) async throws -> RuleDetail {
        async let docRequest = loader.request(Endpoint(method: .get, path: DocPageLoader.path(id)), as: ServerDocDTO.self)
        async let historyRequest = loader.request(
            Endpoint(method: .get, path: DocPageLoader.path(id, "history")),
            as: CursorPageDTO<ServerDocHistoryDTO>.self
        )
        let doc = try await docRequest
        let revisions = ((try? await historyRequest)?.items ?? []).compactMap { $0.toEntity() }
        let acknowledgedAt = acknowledgements.acknowledgedAt(id)
        return RuleDetail(
            rule: doc.toRuleSummary(isAcknowledged: acknowledgedAt != nil, revisionCount: revisions.count),
            articles: doc.articles(),
            acknowledgedAt: acknowledgedAt,
            revisions: revisions
        )
    }

    func acknowledge(ruleId: String) async throws -> Date {
        _ = try await loader.request(Endpoint(method: .post, path: DocPageLoader.path(ruleId, "read")), as: ServerDocReadDTO.self)
        let date = acknowledgements.acknowledgedAt(ruleId) ?? Date()
        acknowledgements.save(date, for: ruleId)
        return date
    }
}
