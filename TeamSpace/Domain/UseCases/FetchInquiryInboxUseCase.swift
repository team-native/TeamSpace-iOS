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
            // 서버가 담당자 목록을 주지 않으면 나에게만 배정할 수 있어요.
            assignees: inbox.assignees.isEmpty ? [user.name] : inbox.assignees
        )
    }
}
