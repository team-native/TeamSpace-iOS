import Foundation

/// 담당자 화면(받은함 · 배정 · 답변) 응답 · 목 서버 저장용 — 구성원 화면은 서버 형식(ServerInquiryDTO)을 읽어요.
/// 담당자 경로는 다음 작업에서 서버(develop) /admin/inquiries 로 맞춰요.

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
