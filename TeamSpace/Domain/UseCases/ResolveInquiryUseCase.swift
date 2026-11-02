import Foundation

/// 11-4 "해결됐어요" — 답변받은 내 문의를 해결됨으로 바꾼 뒤 상세를 다시 불러와요.
struct ResolveInquiryUseCase {
    private let inquiryRepository: InquiryRepository
    private let fetchInquiryDetailUseCase: FetchInquiryDetailUseCase

    init(inquiryRepository: InquiryRepository) {
        self.inquiryRepository = inquiryRepository
        fetchInquiryDetailUseCase = FetchInquiryDetailUseCase(inquiryRepository: inquiryRepository)
    }

    func execute(_ detail: InquiryDetail) async throws -> InquiryDetail {
        guard detail.inquiry.status == .answered, !detail.isResolved else {
            throw AppError.invalidInput("답변을 받은 문의만 해결됨으로 바꿀 수 있어요.")
        }
        try await inquiryRepository.resolve(inquiryId: detail.inquiry.id)
        return try await fetchInquiryDetailUseCase.execute(id: detail.inquiry.id)
    }
}
