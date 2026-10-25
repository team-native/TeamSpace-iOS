import Foundation

/// GET /rules · /rules/{id} 응답의 `data`
/// 명세서에 응답 예시가 없어 Figma 09 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct RuleListResponseDTO: Codable {
    let list: [RuleSummaryDTO]
}

struct RuleSummaryDTO: Codable {
    let id: Int
    let title: String
    let category: RuleCategory
    let department: String
    let version: String
    let status: RuleStatus
    let effectiveAt: Date
    let revisedAt: Date
    let isImportant: Bool
    var isAcknowledged: Bool
    let changeSummary: String?
    let revisionCount: Int

    func toEntity() -> RuleSummary {
        RuleSummary(
            id: id, title: title, category: category, department: department, version: version, status: status,
            effectiveAt: effectiveAt, revisedAt: revisedAt, isImportant: isImportant,
            isAcknowledged: isAcknowledged, changeSummary: changeSummary, revisionCount: revisionCount
        )
    }
}

struct RuleArticleDTO: Codable {
    let number: Int
    let title: String
    let body: String
    let isRevised: Bool
    let changeNote: String?
}

struct RuleDetailDTO: Codable {
    let rule: RuleSummaryDTO
    let articles: [RuleArticleDTO]
    let acknowledgedAt: Date?

    func toEntity() -> RuleDetail {
        RuleDetail(
            rule: rule.toEntity(),
            articles: articles.map {
                RuleArticle(number: $0.number, title: $0.title, body: $0.body, isRevised: $0.isRevised, changeNote: $0.changeNote)
            },
            acknowledgedAt: acknowledgedAt
        )
    }
}

/// POST /rules/{id}/acknowledge 응답의 `data`
struct RuleAcknowledgeResponseDTO: Codable {
    let acknowledgedAt: Date
}
