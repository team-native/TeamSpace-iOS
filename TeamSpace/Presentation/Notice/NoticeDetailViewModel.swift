import Foundation
import Observation

/// 10-6 공지 상세 — "확인했어요"를 누르면 확인하고 목록으로 돌아가요.
@Observable
@MainActor
final class NoticeDetailViewModel {
    private(set) var state: ViewState<NoticeDetail> = .idle
    private(set) var isAcknowledging = false
    private(set) var didAcknowledge = false
    var errorMessage: String?

    private let noticeId: Int
    private let fetchNoticeDetailUseCase: FetchNoticeDetailUseCase
    private let acknowledgeNoticeUseCase: AcknowledgeNoticeUseCase

    init(noticeId: Int, fetchNoticeDetailUseCase: FetchNoticeDetailUseCase, acknowledgeNoticeUseCase: AcknowledgeNoticeUseCase) {
        self.noticeId = noticeId
        self.fetchNoticeDetailUseCase = fetchNoticeDetailUseCase
        self.acknowledgeNoticeUseCase = acknowledgeNoticeUseCase
    }

    var detail: NoticeDetail? { state.value }

    var isAcknowledged: Bool { detail?.acknowledgedAt != nil }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchNoticeDetailUseCase.execute(id: noticeId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "notice.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func acknowledge() async {
        guard let detail = detail, !isAcknowledging else { return }
        isAcknowledging = true
        defer { isAcknowledging = false }
        do {
            state = .loaded(try await acknowledgeNoticeUseCase.execute(detail))
            didAcknowledge = true
        } catch {
            AppLog.record(error, context: "notice.acknowledge")
            errorMessage = error.userMessage
        }
    }
}
