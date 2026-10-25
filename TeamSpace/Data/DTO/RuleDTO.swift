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
    var comparison: RuleArticleComparisonDTO? = nil

    func toEntity() -> RuleArticle {
        RuleArticle(
            number: number, title: title, body: body, isRevised: isRevised, changeNote: changeNote,
            comparison: comparison.map {
                RuleArticleComparison(label: $0.label, previousBody: $0.previousBody, highlight: $0.highlight, reason: $0.reason)
            }
        )
    }
}

struct RuleArticleComparisonDTO: Codable {
    let label: String
    let previousBody: String
    let highlight: String
    let reason: String?
}

struct RuleRevisionDTO: Codable {
    let version: String
    let revisedAt: Date
    let summary: String
    let department: String
    let author: String

    func toEntity() -> RuleRevision {
        RuleRevision(version: version, revisedAt: revisedAt, summary: summary, department: department, author: author)
    }
}

struct RuleDetailDTO: Codable {
    let rule: RuleSummaryDTO
    let articles: [RuleArticleDTO]
    let acknowledgedAt: Date?
    var revisions: [RuleRevisionDTO]? = nil

    func toEntity() -> RuleDetail {
        RuleDetail(
            rule: rule.toEntity(),
            articles: articles.map { $0.toEntity() },
            acknowledgedAt: acknowledgedAt,
            revisions: (revisions ?? []).map { $0.toEntity() }
        )
    }
}

/// POST /rules/{id}/acknowledge 응답의 `data`
struct RuleAcknowledgeResponseDTO: Codable {
    let acknowledgedAt: Date
}
