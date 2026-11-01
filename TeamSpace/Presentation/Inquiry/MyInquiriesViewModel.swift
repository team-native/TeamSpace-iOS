import Foundation
import Observation

/// 11-1 내 문의
@Observable
@MainActor
final class MyInquiriesViewModel {
    private(set) var state: ViewState<[InquirySummary]> = .idle
    var filter: InquiryFilter = .all

    private let fetchMyInquiriesUseCase: FetchMyInquiriesUseCase

    init(fetchMyInquiriesUseCase: FetchMyInquiriesUseCase) {
        self.fetchMyInquiriesUseCase = fetchMyInquiriesUseCase
    }

    var inquiries: [InquirySummary] {
        (state.value ?? []).filter { filter.matches($0) }
    }

    func count(of filter: InquiryFilter) -> Int {
        (state.value ?? []).filter { filter.matches($0) }.count
    }

    var emptyMessage: String {
        filter == .all ? "아직 보낸 문의가 없어요. 오른쪽 위 ‘새 문의’로 의견을 보내 보세요." : "\(filter.title) 상태의 문의가 없어요."
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchMyInquiriesUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "inquiry.mine.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
