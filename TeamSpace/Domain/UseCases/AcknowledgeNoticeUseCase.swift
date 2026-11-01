import Foundation

/// 10-6 "확인했어요" — 이미 확인했으면 다시 보내지 않아요.
struct AcknowledgeNoticeUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(_ detail: NoticeDetail) async throws -> NoticeDetail {
        guard detail.acknowledgedAt == nil else { return detail }
        var updated = detail
        updated.acknowledgedAt = try await noticeRepository.acknowledge(noticeId: detail.notice.id)
        return updated
    }
}
