import Foundation
import Observation

/// 11-5 문의 담당자 받은함 [담당자 운영 화면]
@Observable
@MainActor
final class InquiryInboxViewModel {
    static let recentLogLimit = 3

    private(set) var state: ViewState<InquiryInbox> = .idle
    var query = ""
    var filter: InquiryFilter = .all

    private let user: AuthUser
    private let fetchInquiryInboxUseCase: FetchInquiryInboxUseCase

    init(user: AuthUser, fetchInquiryInboxUseCase: FetchInquiryInboxUseCase) {
        self.user = user
        self.fetchInquiryInboxUseCase = fetchInquiryInboxUseCase
    }

    var department: InquiryDepartment { state.value?.department ?? .unknown }

    /// "NativeOps 담당자 권한"
    var roleTitle: String { "\(department.title) 담당자 권한" }

    private var searched: [InquiryInboxItem] {
        (state.value?.items ?? []).filter { $0.matches(query) }
    }

    var items: [InquiryInboxItem] {
        searched.filter { filter.matches($0.inquiry) }
    }

    /// 칩 옆 숫자 — 검색어를 반영해요.
    func count(of filter: InquiryFilter) -> Int {
        searched.filter { filter.matches($0.inquiry) }.count
    }

    /// 상태 칩 — 받은함에 있는 상태만 (반려는 있을 때만)
    var filters: [InquiryFilter] {
        InquiryFilter.allCases.filter { $0 != .status(.rejected) || count(of: $0) > 0 }
    }

    /// 11-5 최근 처리 이력 — 담당자가 바꾼 상태 변화, 최신순
    var recentLogs: [InquiryInboxLog] {
        let logs = (state.value?.items ?? []).flatMap { item -> [InquiryInboxLog] in
            zip(item.history, item.history.dropFirst()).compactMap { previous, current in
                guard let actor = current.actor else { return nil }
                return InquiryInboxLog(
                    title: item.inquiry.title, occurredAt: current.occurredAt, actor: actor,
                    from: previous.status, to: current.status
                )
            }
        }
        return Array(logs.sorted { $0.occurredAt > $1.occurredAt }.prefix(Self.recentLogLimit))
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchInquiryInboxUseCase.execute(user: user))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "inquiry.inbox.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
