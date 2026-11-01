import Foundation

/// 11-6 공식 답변 · 반려 등록 — 처리 중인 문의에만, 1~2,000자
struct ReplyInquiryUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(_ item: InquiryInboxItem, draft: InquiryReplyDraft) async throws -> InquiryInboxItem {
        guard item.inquiry.status.isOpen else { throw AppError.conflict("이미 처리가 끝난 문의예요.") }
        var trimmed = draft
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.body.isEmpty, trimmed.body.count <= InquiryReplyDraft.bodyLimit else {
            let name = draft.kind == .answer ? "답변" : "반려 사유"
            throw AppError.invalidInput("\(name)은 1~\(InquiryReplyDraft.bodyLimit)자로 써 주세요.")
        }
        return try await inquiryRepository.reply(inquiryId: item.id, draft: trimmed)
    }
}
