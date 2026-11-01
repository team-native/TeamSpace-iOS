import Foundation

/// 11-6 문의 검토 — 담당자만, 처리 이력은 오래된 순
struct FetchInquiryReviewUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(id: Int, user: AuthUser) async throws -> InquiryInboxItem {
        guard user.can(.answerInquiry) else { throw AppError.forbidden("문의 담당자만 볼 수 있어요.") }
        let item = try await inquiryRepository.fetchInboxItem(id: id)
        return InquiryInboxItem(
            inquiry: item.inquiry,
            authorName: item.authorName,
            assignee: item.assignee,
            history: item.history.sorted { $0.occurredAt < $1.occurredAt },
            reference: item.reference
        )
    }
}
