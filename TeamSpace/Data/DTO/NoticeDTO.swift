import Foundation

/// POST /notices 요청 — 첨부는 base64 문자열
/// 서버(develop)는 POST /admin/notices 로 받아요. 공지 작성 맞추기에서 바꿔요.
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
