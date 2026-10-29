import Foundation

/// 10-5 공지 목록 — 고정 공지가 먼저, 그다음 최신순
struct FetchNoticesUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute() async throws -> [NoticeSummary] {
        try await noticeRepository.fetchNotices().sorted { left, right in
            if left.isPinned != right.isPinned { return left.isPinned }
            return left.updatedAt > right.updatedAt
        }
    }
}
