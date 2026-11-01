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
}

struct InquiryReferenceDTO: Codable {
    let kind: InquiryReference.Kind
    let id: Int?
    let title: String
    let summary: String
}

struct InquiryDetailDTO: Codable {
    let inquiry: InquirySummaryDTO
    let history: [InquiryHistoryDTO]
    let reference: InquiryReferenceDTO?

    func toEntity() -> InquiryDetail {
        InquiryDetail(
            inquiry: inquiry.toEntity(),
            history: history.map { InquiryHistory(status: $0.status, occurredAt: $0.occurredAt, note: $0.note) },
            reference: reference.map { InquiryReference(kind: $0.kind, id: $0.id, title: $0.title, summary: $0.summary) }
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
