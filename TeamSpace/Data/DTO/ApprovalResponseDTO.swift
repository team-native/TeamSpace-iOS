import Foundation

/// GET /approvals/mine · /approvals/received 응답의 `data`
/// 명세서에 목록 API 가 없어 Figma 05-1 · 05-2 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ApprovalListResponseDTO: Decodable {
    let list: [ApprovalItemDTO]
}

struct ApprovalItemDTO: Decodable {
    let id: Int
    let kind: ApprovalKind
    let title: String
    let amount: Int?
    let status: ApprovalStatus
    let requesterName: String
    let requesterDepartment: String
    let summary: String?
    let updatedAt: Date

    func toEntity() -> ApprovalItem {
        ApprovalItem(
            id: id,
            kind: kind,
            title: title,
            amount: amount,
            status: status,
            requesterName: requesterName,
            requesterDepartment: requesterDepartment,
            summary: summary,
            updatedAt: updatedAt
        )
    }
}
