import Foundation

/// 공지 수정 — 게시 권한 · 제목 · 본문을 확인하고 같은 공지를 고쳐요. (PATCH /admin/notices/{id})
struct UpdateNoticeUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(noticeId: Int, _ draft: NoticeDraft, user: AuthUser) async throws {
        guard user.can(.publishNotice) else { throw AppError.forbidden("공지 수정 권한이 없어요.") }
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.title.isEmpty, trimmed.title.count <= NoticeDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(NoticeDraft.titleLimit)자로 써 주세요.")
        }
        guard !trimmed.body.isEmpty, trimmed.body.count <= NoticeDraft.bodyLimit else {
            throw AppError.invalidInput("본문은 1~\(NoticeDraft.bodyLimit)자로 써 주세요.")
        }
        try await noticeRepository.update(noticeId: noticeId, trimmed)
    }
}

extension NoticeDraft {
    /// 상세에서 불러온 공지로 수정 칸을 채워요. 수정 알림은 기본으로 꺼 둬요.
    init(editing detail: NoticeDetail, now: Date = Date()) {
        self.init(scheduledAt: now)
        title = detail.notice.title
        body = detail.body
        isImportant = detail.notice.isImportant
        isPinned = detail.notice.isPinned
        sendsPush = false
    }
}
