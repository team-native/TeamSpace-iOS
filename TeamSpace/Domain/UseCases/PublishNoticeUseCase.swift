import Foundation

/// 10-7 전체 공지 게시 — 권한 · 제목 · 본문 · 예약 시각 · 첨부를 확인해요.
struct PublishNoticeUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(_ draft: NoticeDraft, user: AuthUser, asDraft: Bool = false, now: Date = Date()) async throws -> NoticeSummary {
        guard user.can(.publishNotice) else { throw AppError.forbidden("공지 게시 권한이 없어요.") }
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !asDraft {
            guard !trimmed.title.isEmpty, trimmed.title.count <= NoticeDraft.titleLimit else {
                throw AppError.invalidInput("제목은 1~\(NoticeDraft.titleLimit)자로 써 주세요.")
            }
            guard !trimmed.body.isEmpty, trimmed.body.count <= NoticeDraft.bodyLimit else {
                throw AppError.invalidInput("본문은 1~\(NoticeDraft.bodyLimit)자로 써 주세요.")
            }
            if trimmed.timing == .scheduled, trimmed.scheduledAt <= now {
                throw AppError.invalidInput("예약 일시는 지금보다 뒤로 정해 주세요.")
            }
        }
        guard trimmed.attachments.count <= NoticeDraft.attachmentLimit else {
            throw AppError.invalidInput("첨부는 최대 \(NoticeDraft.attachmentLimit)개까지 올릴 수 있어요.")
        }
        return try await noticeRepository.publish(trimmed, asDraft: asDraft)
    }
}
