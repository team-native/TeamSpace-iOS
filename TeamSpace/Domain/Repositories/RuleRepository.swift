import Foundation

/// 규칙 · 제도 저장소
/// 명세서 경로를 쓰지만 응답 예시가 없어 필드는 Figma 09 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol RuleRepository: Sendable {
    /// GET /rules — 규정 목록 및 분류 (명세서)
    func fetchRules() async throws -> [RuleSummary]
    /// GET /rules/{ruleId} — 규정 본문 상세 및 개정 이력 (명세서)
    func fetchRuleDetail(id: Int) async throws -> RuleDetail
    /// POST /rules/{ruleId}/acknowledge — 읽음 확인 (명세서에 없음). 확인한 시각을 돌려줘요.
    func acknowledge(ruleId: Int) async throws -> Date
}
