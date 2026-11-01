import Foundation

/// 11-6 담당 배정 — 답변이 끝난 문의는 바꾸지 않아요.
struct AssignInquiryUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(_ item: InquiryInboxItem, assignee: String) async throws -> InquiryInboxItem {
        guard item.inquiry.status.isOpen else { throw AppError.conflict("이미 처리가 끝난 문의예요.") }
        guard item.assignee != assignee else { return item }
        return try await inquiryRepository.assign(inquiryId: item.id, assignee: assignee)
    }
}
