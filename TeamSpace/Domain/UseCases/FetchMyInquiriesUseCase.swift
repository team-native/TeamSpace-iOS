import Foundation

/// 11-1 내 문의 — 최신순
struct FetchMyInquiriesUseCase {
    private let inquiryRepository: InquiryRepository

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
    }

    func execute() async throws -> [InquirySummary] {
        try await inquiryRepository.fetchMyInquiries().sorted { $0.createdAt > $1.createdAt }
    }
}
