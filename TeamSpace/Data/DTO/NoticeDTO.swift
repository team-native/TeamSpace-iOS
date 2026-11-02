import Foundation

/// POST /admin/notices 요청 (TeamSpace-backend develop `admin.create_notice`)
/// 서버 필수 값은 kind · title · body 이고, pinned · mustRead 를 읽어요.
/// audience · status · publishAt · sendPush 는 서버가 그대로 저장만 해요. (예약 · 임시 저장 · 알림 끄기는 백엔드와 협의 중)
/// PATCH /admin/notices/{id} 요청 — 바꿀 값만 보내요. `sendPush` 가 true 면 서버가 "공지 업데이트" 알림을 보내요.
struct ServerNoticePatchRequestDTO: Codable, Equatable {
    let title: String
    let body: String
    let pinned: Bool
    let mustRead: Bool
    let sendPush: Bool

    init(draft: NoticeDraft) {
        title = draft.title
        body = draft.body
        pinned = draft.isPinned
        mustRead = draft.isImportant
        sendPush = draft.sendsPush
    }
}

struct ServerNoticeCreateRequestDTO: Codable, Equatable {
    enum Status: String, Codable {
        case published = "PUBLISHED"
        case scheduled = "SCHEDULED"
        case draft = "DRAFT"
    }

    /// 앱 작성 화면은 분류를 고르지 않아 항상 "공지"
    static let defaultKind = "공지"

    let kind: String
    let title: String
    let body: String
    let pinned: Bool
    let mustRead: Bool
    let audience: NoticeAudience
    /// POST /uploads 로 받은 파일 id
    let attachments: [String]
    let status: Status
    /// 예약 게시 시각 — 예약이 아니면 nil
    let publishAt: Date?
    let sendPush: Bool

    init(draft: NoticeDraft, attachmentIds: [String], asDraft: Bool) {
        kind = Self.defaultKind
        title = draft.title
        body = draft.body
        pinned = draft.isPinned
        mustRead = draft.isImportant
        audience = draft.audience
        attachments = attachmentIds
        if asDraft {
            status = .draft
        } else {
            status = draft.timing == .scheduled ? .scheduled : .published
        }
        publishAt = !asDraft && draft.timing == .scheduled ? draft.scheduledAt : nil
        sendPush = draft.sendsPush
    }
}
