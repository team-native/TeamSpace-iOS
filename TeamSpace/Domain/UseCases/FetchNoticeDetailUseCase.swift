import Foundation

/// 10-6 공지 상세
struct FetchNoticeDetailUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(id: Int) async throws -> NoticeDetail {
        try await noticeRepository.fetchNotice(id: id)
    }
}
