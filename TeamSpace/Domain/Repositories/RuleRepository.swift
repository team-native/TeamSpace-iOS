import Foundation

/// 규칙 · 제도 저장소 — 서버는 규칙을 문서함 문서(`/docs`, type RULE · FINANCE)로 줘요.
protocol RuleRepository: Sendable {
    /// GET /docs — 운영 규칙 · 재무 문서
    func fetchRules() async throws -> [RuleSummary]
    /// GET /docs/{slug} + /docs/{slug}/history — 본문 조항과 개정 이력
    func fetchRuleDetail(id: String) async throws -> RuleDetail
    /// POST /docs/{slug}/read — 읽음 확인. 확인한 시각을 돌려줘요.
    func acknowledge(ruleId: String) async throws -> Date
    /// POST /admin/docs — 규칙 등록 · 개정 (Admin). 저장한 slug 를 돌려줘요.
    func saveRule(_ draft: RuleDraft, slug: String) async throws -> String
}
