import Foundation

/// GET /notices · /notices/{id} · POST /notices 응답의 `data`
/// 명세서에서 응답 예시를 찾지 못해 Figma 10-5 ~ 10-7 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct NoticeListResponseDTO: Codable {
    let list: [NoticeSummaryDTO]
}

struct NoticeDetailDTO: Codable {
    struct LinkedDocument: Codable {
        let id: Int
        let title: String
        let category: String
    }

    let notice: NoticeSummaryDTO
    let authorName: String
    let authorRole: String
    let body: String
    let viewCount: Int
    let linkedDocument: LinkedDocument?
    let acknowledgedAt: Date?

    func toEntity() -> NoticeDetail {
        NoticeDetail(
            notice: notice.toEntity(),
            authorName: authorName,
            authorRole: authorRole,
            body: body,
            viewCount: viewCount,
            linkedDocument: linkedDocument.map {
                NoticeLinkedDocument(id: $0.id, title: $0.title, category: LibraryCategory(rawValue: $0.category) ?? .unknown)
            },
            acknowledgedAt: acknowledgedAt
        )
    }
}

struct NoticeAcknowledgeResponseDTO: Codable {
    let acknowledgedAt: Date
}

/// POST /notices 요청 — 첨부는 base64 문자열 (업로드 방식은 백엔드와 맞춰야 함)
struct NoticePublishRequestDTO: Codable {
    struct Attachment: Codable {
        let fileName: String
        let data: String
    }

    let audience: NoticeAudience
    let isImportant: Bool
    let isPinned: Bool
    let title: String
    let body: String
    let attachments: [Attachment]
    /// 지금 게시면 nil
    let scheduledAt: Date?
    let sendsPush: Bool
    /// 임시 저장이면 true
    let isDraft: Bool
}
