import Foundation

/// GET /inquiries/mine · /inquiries/{id} · POST /inquiries 응답의 `data`
/// 명세서에서 응답 예시를 찾지 못해 Figma 11 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct InquiryListResponseDTO: Codable {
    let list: [InquirySummaryDTO]
}

struct InquiryReplyDTO: Codable {
    let department: InquiryDepartment
    let body: String
    let repliedAt: Date

    func toEntity() -> InquiryReply {
        InquiryReply(department: department, body: body, repliedAt: repliedAt)
    }
}

struct InquirySummaryDTO: Codable {
    let id: Int
    let department: InquiryDepartment
    let title: String
    let body: String
    let isAnonymous: Bool
    let createdAt: Date
    var status: InquiryStatus
    var reply: InquiryReplyDTO?

    func toEntity() -> InquirySummary {
        InquirySummary(
            id: id, department: department, title: title, body: body, isAnonymous: isAnonymous,
            createdAt: createdAt, status: status, reply: reply?.toEntity()
        )
    }
}

struct InquiryHistoryDTO: Codable {
    let status: InquiryStatus
    let occurredAt: Date
    let note: String
    var actor: String? = nil

    func toEntity() -> InquiryHistory {
        InquiryHistory(status: status, occurredAt: occurredAt, note: note, actor: actor)
    }
}

struct InquiryReferenceDTO: Codable {
    let kind: InquiryReference.Kind
    let id: Int?
    let title: String
    let summary: String

    func toEntity() -> InquiryReference {
        InquiryReference(kind: kind, id: id, title: title, summary: summary)
    }
}

struct InquiryDetailDTO: Codable {
    let inquiry: InquirySummaryDTO
    let history: [InquiryHistoryDTO]
    let reference: InquiryReferenceDTO?

    func toEntity() -> InquiryDetail {
        InquiryDetail(
            inquiry: inquiry.toEntity(),
            history: history.map { $0.toEntity() },
            reference: reference?.toEntity()
        )
    }
}

/// POST /inquiries 요청
struct InquirySubmitRequestDTO: Codable {
    let department: InquiryDepartment
    let title: String
    let body: String
    let isAnonymous: Bool
    let followUpOf: Int?
}

/// GET /inquiries/inbox · /inquiries/inbox/{id} 응답의 `data` (담당자 화면)
struct InquiryInboxItemDTO: Codable {
    let inquiry: InquirySummaryDTO
    let authorName: String?
    let assignee: String?
    let history: [InquiryHistoryDTO]
    let reference: InquiryReferenceDTO?

    func toEntity() -> InquiryInboxItem {
        InquiryInboxItem(
            inquiry: inquiry.toEntity(),
            authorName: inquiry.isAnonymous ? nil : authorName,
            assignee: assignee,
            history: history.map { $0.toEntity() },
            reference: reference?.toEntity()
        )
    }
}

struct InquiryInboxResponseDTO: Codable {
    let department: InquiryDepartment
    let list: [InquiryInboxItemDTO]
    let assignees: [String]

    func toEntity() -> InquiryInbox {
        InquiryInbox(department: department, items: list.map { $0.toEntity() }, assignees: assignees)
    }
}

/// PATCH /inquiries/{id}/assignee 요청
struct InquiryAssignRequestDTO: Codable {
    let assignee: String
}

/// POST /inquiries/{id}/reply 요청
struct InquiryReplyRequestDTO: Codable {
    /// ANSWER · REJECT
    let kind: String
    let body: String
    let referenceRuleId: Int?
}
