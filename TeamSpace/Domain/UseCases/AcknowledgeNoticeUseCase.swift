import Foundation

/// 10-6 "확인했어요" — 이미 확인했으면 다시 보내지 않아요.
struct AcknowledgeNoticeUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(_ detail: NoticeDetail, now: Date = Date()) async throws -> NoticeDetail {
        guard !detail.isAcknowledged else { return detail }
        try await noticeRepository.acknowledge(noticeId: detail.notice.id)
        var updated = detail
        updated.isAcknowledged = true
        updated.acknowledgedAt = now
        return updated
    }
}
