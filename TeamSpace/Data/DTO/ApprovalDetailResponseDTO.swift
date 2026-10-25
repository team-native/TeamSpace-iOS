import Foundation

/// GET /documents/{documentId} 응답의 `data`
/// 명세서에 응답 예시가 없어 Figma 05-3 · 05-4 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ApprovalDetailResponseDTO: Decodable {
    let document: ApprovalItemDTO
    let fields: [ApprovalFieldDTO]
    let reason: String
    let approvers: [ApproverDTO]
    let attachments: [ApprovalAttachmentDTO]
    let comments: [ApprovalCommentDTO]
    let isMine: Bool
    let myApprovalId: Int?

    func toEntity() -> ApprovalDetail {
        ApprovalDetail(
            item: document.toEntity(),
            fields: fields.map { ApprovalField(title: $0.title, value: $0.value) },
            reason: reason,
            approvers: approvers.map { $0.toEntity() },
            attachments: attachments.map { ApprovalAttachment(name: $0.name, sizeText: $0.sizeText) },
            comments: comments.map { $0.toEntity() },
            isMine: isMine,
            myApprovalId: myApprovalId
        )
    }
}

struct ApprovalFieldDTO: Decodable {
    let title: String
    let value: String
}

struct ApproverDTO: Decodable {
    let approvalId: Int
    let name: String
    let role: String
    let status: ApproverStatus
    let note: String

    func toEntity() -> Approver {
        Approver(id: approvalId, name: name, role: role, status: status, note: note)
    }
}

struct ApprovalAttachmentDTO: Decodable {
    let name: String
    let sizeText: String
}

struct ApprovalCommentDTO: Decodable {
    let id: Int
    let authorName: String
    let body: String
    let createdAt: Date

    func toEntity() -> ApprovalComment {
        ApprovalComment(id: id, authorName: authorName, body: body, createdAt: createdAt)
    }
}

/// POST /approvals/{approvalId}/decide 요청 바디
struct ApprovalDecisionRequestDTO: Codable {
    /// "APPROVE" | "REJECT"
    let decision: String
    /// 반려 사유 · 검토 의견
    let comment: String?
}

/// POST /approvals/{approvalId}/decide 응답의 `data`
struct ApprovalDecisionResponseDTO: Decodable {
    let status: ApprovalStatus
    let nextApproverName: String?

    func toEntity() -> ApprovalDecisionResult {
        ApprovalDecisionResult(status: status, nextApproverName: nextApproverName)
    }
}

/// POST /documents/{documentId}/comments 요청 바디
struct ApprovalCommentRequestDTO: Codable {
    let body: String
}
