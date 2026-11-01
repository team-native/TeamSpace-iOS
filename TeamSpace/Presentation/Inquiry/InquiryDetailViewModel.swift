import Foundation
import Observation

/// 11-4 문의 상세 · 작성자 / 11-7 반려
@Observable
@MainActor
final class InquiryDetailViewModel {
    private(set) var state: ViewState<InquiryDetail> = .idle

    private let inquiryId: Int
    private let fetchInquiryDetailUseCase: FetchInquiryDetailUseCase

    init(inquiryId: Int, fetchInquiryDetailUseCase: FetchInquiryDetailUseCase) {
        self.inquiryId = inquiryId
        self.fetchInquiryDetailUseCase = fetchInquiryDetailUseCase
    }

    var detail: InquiryDetail? { state.value }

    /// 답변 완료 → "이 답변에 후속 문의하기", 반려 → "다시 문의하기", 처리 중이면 없음
    var followUpTitle: String? {
        switch detail?.inquiry.status {
        case .answered: return "이 답변에 후속 문의하기"
        case .rejected: return "다시 문의하기"
        default: return nil
        }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchInquiryDetailUseCase.execute(id: inquiryId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "inquiry.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
