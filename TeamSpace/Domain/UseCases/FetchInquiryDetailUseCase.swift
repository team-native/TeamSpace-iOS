import Foundation

/// 11-4 문의 상세 — 처리 이력은 오래된 순
struct FetchInquiryDetailUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute(id: Int) async throws -> InquiryDetail {
        let detail = try await inquiryRepository.fetchInquiry(id: id)
        return InquiryDetail(
            inquiry: detail.inquiry,
            history: detail.history.sorted { $0.occurredAt < $1.occurredAt },
            reference: detail.reference,
            followUps: detail.followUps.sorted { $0.sentAt < $1.sentAt }
        )
    }
}
