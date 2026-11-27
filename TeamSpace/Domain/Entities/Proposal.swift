import Foundation

/// 12-1b 운영 제안 한 건
struct ProposalSummary: Equatable, Identifiable, Sendable {
    let id: Int
    /// 검토하는 부서 (예: NativeOps · NativeLab)
    let department: String
    let title: String
    let excerpt: String
    let isAnonymous: Bool
    /// 익명이면 nil
    let authorName: String?
    let createdAt: Date
    let status: ProposalStatus
    var recommendCount: Int
    var commentCount: Int
    let isMine: Bool
}

/// 12-2b 진행 상태 한 단계 — 도달한 날짜
struct ProposalStep: Equatable, Sendable {
    let status: ProposalStatus
    let reachedAt: Date
}

/// 12-2b 담당 부서 답변
struct ProposalAnswer: Equatable, Sendable {
    let department: String
    let body: String
    let answeredAt: Date
}

/// 12-2b 댓글
struct ProposalComment: Equatable, Identifiable, Sendable {
    let id: Int
    let authorName: String?
    let isAnonymous: Bool
    /// 제안한 사람이 단 댓글
    let isProposer: Bool
    let isMine: Bool
    let body: String
    let createdAt: Date
    /// 익명 댓글의 작성자별 번호 — "익명 2"
    var anonymousNumber: Int?
}

/// 12-2b 운영 제안 상세
struct ProposalDetail: Equatable, Sendable {
    var proposal: ProposalSummary
    let body: String
    /// 서버가 조회 수를 주지 않으면 nil
    let viewCount: Int?
    /// 내가 추천했는지 (1인 1회)
    var isRecommended: Bool
    let steps: [ProposalStep]
    let answer: ProposalAnswer?
    var comments: [ProposalComment]
}

/// POST /proposals/{id}/recommend 결과
struct ProposalRecommend: Equatable, Sendable {
    let isRecommended: Bool
    let recommendCount: Int
}

/// 12-3 운영 제안 쓰기 (임시 저장도 이 모양 그대로)
struct ProposalDraft: Equatable, Codable, Sendable {
    static let titleLimit = 60
    static let bodyLimit = 2_000
    /// 12-3 대상 부서
    static let departments = ["NativeOps", "PMO", "FA", "Design"]

    var department = "NativeOps"
    var title = ""
    var body = ""
    var isAnonymous = true

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 서버 담당 부서(`dept`) — 서버는 공식 부서와 "PM / PO" · "전공 리더" 만 받아서 PMO 는 "PM / PO" 로 보내요.
    static func serverDepartment(_ department: String) -> String {
        department == "PMO" ? "PM / PO" : department
    }

    /// 서버 값을 칩 이름으로 ("PM / PO" → PMO, "Design & Client" → Design)
    static func chipDepartment(_ server: String) -> String {
        switch server {
        case "PM / PO", "PM/PO", "PM", "PO": return "PMO"
        case "Design & Client": return "Design"
        default: return server
        }
    }
}
