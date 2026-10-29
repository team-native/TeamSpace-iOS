import Foundation

/// 10 공지 저장소
/// 명세서에서 공지 응답 예시를 찾지 못해 경로 · 필드는 Figma 10-5 ~ 10-7 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol NoticeRepository: Sendable {
    /// GET /notices — 10-5 공지 목록 (게시된 것만)
    func fetchNotices() async throws -> [NoticeSummary]
    /// GET /notices/{noticeId} — 10-6 공지 상세
    func fetchNotice(id: Int) async throws -> NoticeDetail
    /// POST /notices/{noticeId}/acknowledge — 10-6 "확인했어요" (확인한 시각)
    func acknowledge(noticeId: Int) async throws -> Date
    /// POST /notices — 10-7 게시 · 예약 게시 · 임시 저장
    func publish(_ draft: NoticeDraft, asDraft: Bool) async throws -> NoticeSummary
}
