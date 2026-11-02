import Foundation

/// 목 서버(MockProposalStore)가 기억하는 운영 제안 모양 — 응답은 서버 형식(ServerProposalDTO)으로 바꿔 내보내요.
struct ProposalSummaryDTO: Codable {
    let id: Int
    let department: String
    let title: String
    let excerpt: String
    let isAnonymous: Bool
    let authorName: String?
    let createdAt: Date
    var status: ProposalStatus
    var recommendCount: Int
    var commentCount: Int
    let isMine: Bool

    func toEntity() -> ProposalSummary {
        ProposalSummary(
            id: id, department: department, title: title, excerpt: excerpt, isAnonymous: isAnonymous,
            authorName: isAnonymous ? nil : authorName, createdAt: createdAt, status: status,
            recommendCount: recommendCount, commentCount: commentCount, isMine: isMine
        )
    }
}

struct ProposalStepDTO: Codable {
    let status: ProposalStatus
    let reachedAt: Date
}

struct ProposalAnswerDTO: Codable {
    let department: String
    let body: String
    let answeredAt: Date
}

struct ProposalCommentDTO: Codable {
    let id: Int
    let authorName: String?
    let isAnonymous: Bool
    let isProposer: Bool
    let isMine: Bool
    let body: String
    let createdAt: Date

    func toEntity() -> ProposalComment {
        ProposalComment(
            id: id, authorName: isAnonymous ? nil : authorName, isAnonymous: isAnonymous,
            isProposer: isProposer, isMine: isMine, body: body, createdAt: createdAt
        )
    }
}

