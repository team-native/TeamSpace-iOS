import Foundation
import Observation

/// 05-1 · 05-2 결재 탭
@Observable
@MainActor
final class ApprovalListViewModel {
    /// 내가 올린 결재 목록에서 처음 보여줄 개수 (Figma: 4건)
    static let recentCount = 4

    private(set) var state: ViewState<ApprovalBox> = .idle
    var tab: ApprovalTab = .mine

    private let fetchApprovalBoxUseCase: FetchApprovalBoxUseCase

    init(fetchApprovalBoxUseCase: FetchApprovalBoxUseCase) {
        self.fetchApprovalBoxUseCase = fetchApprovalBoxUseCase
    }

    private var mine: [ApprovalItem] {
        state.value?.mine ?? []
    }

    private var received: [ApprovalItem] {
        state.value?.received ?? []
    }

    /// 상단 요약 (작성 중 · 결재 대기 · 검토 중 · 승인 · 반려)
    let summaryStatuses: [ApprovalStatus] = [.draft, .pending, .reviewing, .approved, .rejected]

    func count(of status: ApprovalStatus) -> Int {
        mine.filter { $0.status == status }.count
    }

    var myTotalCount: Int { mine.count }

    var recentMine: [ApprovalItem] {
        Array(mine.prefix(Self.recentCount))
    }

    /// 검토를 기다리는 받은 결재
    var waitingReceived: [ApprovalItem] {
        received.filter { $0.status.isWaiting }
    }

    /// 이번 달에 처리한 받은 결재
    func handledThisMonth(now: Date = Date(), calendar: Calendar = .current) -> [ApprovalItem] {
        received.filter { $0.status.isHandled && calendar.isDate($0.updatedAt, equalTo: now, toGranularity: .month) }
    }

    /// 세그먼트 제목 "받은 결재 2"
    func title(for tab: ApprovalTab) -> String {
        switch tab {
        case .mine: return "내가 올린 결재"
        case .received: return waitingReceived.isEmpty ? "받은 결재" : "받은 결재 \(waitingReceived.count)"
        }
    }

    var headline: String {
        switch tab {
        case .mine:
            return "필요한 안건을\n결재로 올려요."
        case .received:
            return waitingReceived.isEmpty
                ? "검토를 기다리는\n요청이 없어요."
                : "검토를 기다리는\n요청이 \(waitingReceived.count)건 있어요."
        }
    }

    var eyebrow: String {
        tab == .mine ? "APPROVAL · 결재 현황" : "APPROVAL · 받은 결재"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchApprovalBoxUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "approval.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
