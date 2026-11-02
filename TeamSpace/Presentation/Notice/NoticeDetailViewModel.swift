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
    private let fetchNoticeUnconfirmedUseCase: FetchNoticeUnconfirmedUseCase?
    private let user: AuthUser?
    /// 미확인자 시트
    var isUnconfirmedPresented = false
    private(set) var unconfirmedState: ViewState<[NoticeUnconfirmedMember]> = .idle

    init(
        noticeId: Int,
        fetchNoticeDetailUseCase: FetchNoticeDetailUseCase,
        acknowledgeNoticeUseCase: AcknowledgeNoticeUseCase,
        fetchNoticeUnconfirmedUseCase: FetchNoticeUnconfirmedUseCase? = nil,
        user: AuthUser? = nil
    ) {
        self.noticeId = noticeId
        self.fetchNoticeDetailUseCase = fetchNoticeDetailUseCase
        self.acknowledgeNoticeUseCase = acknowledgeNoticeUseCase
        self.fetchNoticeUnconfirmedUseCase = fetchNoticeUnconfirmedUseCase
        self.user = user
    }

    /// Admin 이면 확인 현황 카드를 보여줘요.
    var canSeeReceipts: Bool { detail != nil && user?.can(.viewNoticeReceipts) == true }

    /// "12 / 24명 확인"
    var receiptText: String? {
        guard canSeeReceipts, let detail, detail.memberCount > 0 else { return nil }
        return "\(detail.confirmedCount) / \(detail.memberCount)명 확인"
    }

    /// 0 ~ 1
    var receiptProgress: Double {
        guard let detail, detail.memberCount > 0 else { return 0 }
        return min(1, Double(detail.confirmedCount) / Double(detail.memberCount))
    }

    func showUnconfirmed() async {
        isUnconfirmedPresented = true
        await loadUnconfirmed()
    }

    func loadUnconfirmed() async {
        guard let user, let fetchNoticeUnconfirmedUseCase else { return }
        unconfirmedState = .loading
        do {
            let members = try await fetchNoticeUnconfirmedUseCase.execute(noticeId: noticeId, user: user)
            unconfirmedState = members.isEmpty ? .empty : .loaded(members)
        } catch AppError.forbidden {
            unconfirmedState = .forbidden
        } catch {
            AppLog.record(error, context: "notice.unconfirmed")
            unconfirmedState = .failed(error)
        }
    }

    /// 공지 게시 권한(FA · Leader · Admin)이 있으면 고칠 수 있어요.
    var canEdit: Bool { detail != nil && user?.can(.publishNotice) == true }

    var detail: NoticeDetail? { state.value }

    var isAcknowledged: Bool { detail?.isAcknowledged == true }

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
