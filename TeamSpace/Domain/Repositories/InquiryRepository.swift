import Foundation

/// 11 익명 문의 · 건의 저장소 (TeamSpace-backend develop `community.py` 문의)
/// 담당자 화면은 /admin/inquiries 를 써요.
protocol InquiryRepository: Sendable {
    /// GET /inquiries — 11-1 내가 보낸 문의
    func fetchMyInquiries() async throws -> [InquirySummary]
    /// 11-4 · 11-7 문의 상세 (작성자 본인) — 서버에 상세 경로가 없어 GET /inquiries 에서 찾아요.
    func fetchInquiry(id: Int) async throws -> InquiryDetail
    /// POST /inquiries — 11-2 문의 제출 · 답변받은 문의의 후속 문의는 POST /inquiries/{id}/comments
    func submit(_ draft: InquiryDraft) async throws -> InquirySummary
    /// GET /admin/inquiries — 11-5 담당 부서 받은함
    func fetchInbox() async throws -> InquiryInbox
    /// 11-6 검토 화면 — 서버에 상세 경로가 없어 GET /admin/inquiries 에서 찾아요.
    func fetchInboxItem(id: Int) async throws -> InquiryInboxItem
    /// PATCH /admin/inquiries/{inquiryId} — 담당 배정 (검토 중으로 바뀌어요)
    func assign(inquiryId: Int, assignee: String) async throws -> InquiryInboxItem
    /// POST /admin/inquiries/{inquiryId}/answer · PATCH (반려) — 공식 답변 · 반려 등록 (작성자에게 알림)
    func reply(inquiryId: Int, draft: InquiryReplyDraft) async throws -> InquiryInboxItem
}
