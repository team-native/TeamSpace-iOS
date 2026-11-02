import Foundation

/// 10-5 공지 목록 — 서버가 고정 공지 먼저, 그다음 최신순으로 줘요.
struct FetchNoticesUseCase {
    static let pageSize = 30

    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(cursor: String? = nil) async throws -> CursorPage<NoticeSummary> {
        try await noticeRepository.fetchNotices(cursor: cursor, limit: Self.pageSize)
    }
}
