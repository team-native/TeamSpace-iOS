import Foundation

/// 11-5 문의 받은함 — 담당자만, 최신 접수순
struct FetchInquiryInboxUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(user: AuthUser) async throws -> InquiryInbox {
        guard user.can(.answerInquiry) else { throw AppError.forbidden("문의 담당자만 볼 수 있어요.") }
        let inbox = try await inquiryRepository.fetchInbox()
        return InquiryInbox(
            department: inbox.department,
            items: inbox.items.sorted { $0.inquiry.createdAt > $1.inquiry.createdAt },
            assignees: inbox.assignees
        )
    }
}
