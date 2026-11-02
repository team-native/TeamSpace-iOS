import Foundation

/// 목 서버(MockInquiryStore)가 기억하는 문의 모양 — 응답은 서버 형식(ServerInquiryDTO)으로 바꿔 내보내요.
/// InquiryReferenceDTO 는 서버 payload 의 reference 를 읽을 때도 써요.

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
