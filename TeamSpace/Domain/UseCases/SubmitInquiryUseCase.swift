import Foundation

/// 11-2 문의 제출 — 대상 · 제목 · 내용을 확인해요.
struct SubmitInquiryUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(_ draft: InquiryDraft) async throws -> InquirySummary {
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard InquiryDepartment.selectable.contains(trimmed.department) else {
            throw AppError.invalidInput("문의 대상을 골라 주세요.")
        }
        guard !trimmed.title.isEmpty, trimmed.title.count <= InquiryDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(InquiryDraft.titleLimit)자로 써 주세요.")
        }
        guard !trimmed.body.isEmpty, trimmed.body.count <= InquiryDraft.bodyLimit else {
            throw AppError.invalidInput("내용은 1~\(InquiryDraft.bodyLimit)자로 써 주세요.")
        }
        return try await inquiryRepository.submit(trimmed)
    }
}
