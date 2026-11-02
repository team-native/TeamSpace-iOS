import Foundation

/// 10 공지 저장소 (TeamSpace-backend develop `community.py` 공지)
protocol NoticeRepository: Sendable {
    /// GET /notices — 10-5 공지 목록 (고정 → 최신순, 커서 페이지)
    func fetchNotices(cursor: String?, limit: Int) async throws -> CursorPage<NoticeSummary>
    /// GET /notices/{noticeId} — 10-6 공지 상세
    func fetchNotice(id: Int) async throws -> NoticeDetail
    /// POST /notices/{noticeId}/confirm — 10-6 "확인했어요"
    func acknowledge(noticeId: Int) async throws
    /// POST /notices — 10-7 게시 · 예약 게시 · 임시 저장 (서버 형식은 다음 작업에서 맞춰요)
    func publish(_ draft: NoticeDraft, asDraft: Bool) async throws -> NoticeSummary
}
