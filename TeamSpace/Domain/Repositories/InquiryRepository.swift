import Foundation

/// 11 익명 문의 · 건의 저장소 (TeamSpace-backend develop `community.py` 문의)
/// 담당자 화면(받은함 · 배정 · 답변) 경로는 아직 예전 형식이에요. (다음 작업에서 /admin/inquiries 로 맞춰요)
protocol InquiryRepository: Sendable {
    /// GET /inquiries — 11-1 내가 보낸 문의
    func fetchMyInquiries() async throws -> [InquirySummary]
    /// 11-4 · 11-7 문의 상세 (작성자 본인) — 서버에 상세 경로가 없어 GET /inquiries 에서 찾아요.
    func fetchInquiry(id: Int) async throws -> InquiryDetail
    /// POST /inquiries — 11-2 문의 제출
    func submit(_ draft: InquiryDraft) async throws -> InquirySummary
    /// GET /inquiries/inbox — 11-5 담당 부서 받은함
    func fetchInbox() async throws -> InquiryInbox
    /// GET /inquiries/inbox/{inquiryId} — 11-6 검토 화면
    func fetchInboxItem(id: Int) async throws -> InquiryInboxItem
    /// PATCH /inquiries/{inquiryId}/assignee — 담당 배정 (접수면 검토 중으로 바뀌어요)
    func assign(inquiryId: Int, assignee: String) async throws -> InquiryInboxItem
    /// POST /inquiries/{inquiryId}/reply — 공식 답변 · 반려 등록 (작성자에게 알림)
    func reply(inquiryId: Int, draft: InquiryReplyDraft) async throws -> InquiryInboxItem
}
