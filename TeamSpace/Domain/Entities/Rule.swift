import Foundation

/// 규칙 분류
enum RuleCategory: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case operation = "OPERATION"   // 운영
    case people = "PEOPLE"         // 인사·조직
    case project = "PROJECT"       // 프로젝트
    case finance = "FINANCE"       // 재정
    case unknown = "UNKNOWN"

    static let unknownCase: RuleCategory = .unknown
    static let selectable: [RuleCategory] = [.operation, .people, .project, .finance]
}

/// 규칙 시행 상태
enum RuleStatus: String, UnknownCaseDecodable, Encodable, Hashable, Sendable {
    case active = "ACTIVE"         // 시행 중
    case scheduled = "SCHEDULED"   // 시행 예정
    case unknown = "UNKNOWN"

    static let unknownCase: RuleStatus = .unknown
}

/// 09-1 규칙 목록 한 건
struct RuleSummary: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let category: RuleCategory
    /// 담당 부서
    let department: String
    /// 예) "v1.3"
    let version: String
    let status: RuleStatus
    let effectiveAt: Date
    let revisedAt: Date
    /// 꼭 읽어야 하는 중요 개정
    let isImportant: Bool
    /// 읽음 확인을 했는지
    var isAcknowledged: Bool
    /// 이번 개정 요약 (예: "검토 기한 3주 → 2주")
    let changeSummary: String?
    let revisionCount: Int

    /// 최근 30일 안에 개정됐는지
    func isRecentlyRevised(now: Date = Date()) -> Bool {
        now.timeIntervalSince(revisedAt) <= 30 * 86_400
    }
}

/// 조항 한 개
struct RuleArticle: Equatable, Identifiable, Sendable {
    /// 제 N 조
    let number: Int
    let title: String
    let body: String
    /// 이번 개정에서 바뀐 조항
    let isRevised: Bool
    /// 바뀐 점 (예: "검토 기한 3주 → 2주로 단축")
    let changeNote: String?

    var id: Int { number }
}

/// 09-2 규칙 상세
struct RuleDetail: Equatable, Sendable {
    var rule: RuleSummary
    let articles: [RuleArticle]
    var acknowledgedAt: Date?
}
