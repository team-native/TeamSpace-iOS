import Foundation

/// 10-7 공지 대상 조직
enum NoticeAudience: String, CaseIterable, Codable, Hashable, Sendable {
    case native = "NATIVE"
    case inspace = "INSPACE"
}

/// 10-7 게시 시점
enum NoticePublishTiming: Hashable, Sendable {
    case now
    case scheduled
}

/// 10-7 첨부 파일 한 개
struct NoticeAttachment: Equatable, Identifiable, Sendable {
    let id = UUID()
    let fileName: String
    let data: Data

    static func == (lhs: NoticeAttachment, rhs: NoticeAttachment) -> Bool {
        lhs.id == rhs.id
    }
}

/// 10-7 전체 공지 작성 내용
struct NoticeDraft: Equatable, Sendable {
    static let titleLimit = 60
    static let bodyLimit = 5_000
    static let attachmentLimit = 5
    static let attachmentByteLimit = 20 * 1_024 * 1_024

    var audience: NoticeAudience = .native
    var isImportant = true
    var isPinned = true
    var title = ""
    var body = ""
    var attachments: [NoticeAttachment] = []
    var timing: NoticePublishTiming = .now
    var scheduledAt: Date
    var sendsPush = true

    init(scheduledAt: Date) {
        self.scheduledAt = scheduledAt
    }
}
