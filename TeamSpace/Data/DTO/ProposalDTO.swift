import Foundation

/// GET /proposals · /proposals/{id} 응답의 `data`
/// 명세서에서 응답 예시를 찾지 못해 Figma 12 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ProposalListResponseDTO: Codable {
    let list: [ProposalSummaryDTO]
}

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

struct ProposalDetailDTO: Codable {
    let proposal: ProposalSummaryDTO
    let body: String
    let viewCount: Int
    let isRecommended: Bool
    let steps: [ProposalStepDTO]
    let answer: ProposalAnswerDTO?
    let comments: [ProposalCommentDTO]

    func toEntity() -> ProposalDetail {
        ProposalDetail(
            proposal: proposal.toEntity(),
            body: body,
            viewCount: viewCount,
            isRecommended: isRecommended,
            steps: steps.map { ProposalStep(status: $0.status, reachedAt: $0.reachedAt) },
            answer: answer.map { ProposalAnswer(department: $0.department, body: $0.body, answeredAt: $0.answeredAt) },
            comments: comments.map { $0.toEntity() }
        )
    }
}

struct ProposalRecommendResponseDTO: Codable {
    let isRecommended: Bool
    let recommendCount: Int
}

/// POST /proposals/{id}/comments 요청
struct ProposalCommentRequestDTO: Codable {
    let body: String
    let isAnonymous: Bool
}

/// POST /proposals 요청
struct ProposalCreateRequestDTO: Codable {
    let department: String
    let title: String
    let body: String
    let isAnonymous: Bool
}
