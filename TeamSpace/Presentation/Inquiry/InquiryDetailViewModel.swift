import Foundation
import Observation

/// 11-4 문의 상세 · 작성자 / 11-7 반려
@Observable
@MainActor
final class InquiryDetailViewModel {
    private(set) var state: ViewState<InquiryDetail> = .idle
    private(set) var isResolving = false
    var toastMessage: String?
    var errorMessage: String?

    private let inquiryId: Int
    private let fetchInquiryDetailUseCase: FetchInquiryDetailUseCase
    private let resolveInquiryUseCase: ResolveInquiryUseCase?

    init(
        inquiryId: Int,
        fetchInquiryDetailUseCase: FetchInquiryDetailUseCase,
        resolveInquiryUseCase: ResolveInquiryUseCase? = nil
    ) {
        self.inquiryId = inquiryId
        self.fetchInquiryDetailUseCase = fetchInquiryDetailUseCase
        self.resolveInquiryUseCase = resolveInquiryUseCase
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

    /// 답변받았고 아직 해결 전이면 "해결됐어요"를 보여줘요.
    var canResolve: Bool {
        guard let detail, resolveInquiryUseCase != nil else { return false }
        return detail.inquiry.status == .answered && !detail.isResolved
    }

    /// "11.03 09:12 해결됨으로 표시했어요"
    var resolvedText: String? {
        detail?.resolvedAt.map { "\(TSFormat.dateTime($0)) 해결됨으로 표시했어요" }
    }

    func resolve() async {
        guard let detail, canResolve, !isResolving, let resolveInquiryUseCase else { return }
        isResolving = true
        defer { isResolving = false }
        do {
            state = .loaded(try await resolveInquiryUseCase.execute(detail))
            toastMessage = "해결됨으로 표시했어요"
        } catch {
            AppLog.record(error, context: "inquiry.resolve")
            errorMessage = error.userMessage
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
