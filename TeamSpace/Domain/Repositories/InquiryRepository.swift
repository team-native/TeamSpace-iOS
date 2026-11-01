import Foundation

/// 11 익명 문의 · 건의 저장소
/// 명세서에서 응답 예시를 찾지 못해 경로 · 필드는 Figma 11 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol InquiryRepository: Sendable {
    /// GET /inquiries/mine — 11-1 내가 보낸 문의
    func fetchMyInquiries() async throws -> [InquirySummary]
    /// GET /inquiries/{inquiryId} — 11-4 · 11-7 문의 상세 (작성자 본인)
    func fetchInquiry(id: Int) async throws -> InquiryDetail
    /// POST /inquiries — 11-2 문의 제출
    func submit(_ draft: InquiryDraft) async throws -> InquirySummary
}
