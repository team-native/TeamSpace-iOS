import Foundation
import Observation

/// 05-9 · 05-10 커스텀 알림창
enum ApprovalDialog: Equatable {
    /// 05-9 승인 확인
    case approveConfirm
    /// 05-10 처리 완료
    case completed(ApprovalDecision)
}

/// 05-3 내 결재 상세 · 05-4 받은 결재 상세 (검토)
@Observable
@MainActor
final class ApprovalDetailViewModel {
    private(set) var state: ViewState<ApprovalDetail> = .idle
    private(set) var isProcessing = false
    var commentDraft = ""
    var rejectReason = ""
    var dialog: ApprovalDialog?
    var isRejectAlertPresented = false
    var isWithdrawConfirmPresented = false
    var toastMessage: String?
    /// 요청 취소가 끝나면 이전 화면으로 돌아가요.
    private(set) var didWithdraw = false

    let documentId: Int
    private let fetchApprovalDetailUseCase: FetchApprovalDetailUseCase
    private let decideApprovalUseCase: DecideApprovalUseCase
    private let addApprovalCommentUseCase: AddApprovalCommentUseCase
    private let withdrawApprovalUseCase: WithdrawApprovalUseCase

    init(
        documentId: Int,
        fetchApprovalDetailUseCase: FetchApprovalDetailUseCase,
        decideApprovalUseCase: DecideApprovalUseCase,
        addApprovalCommentUseCase: AddApprovalCommentUseCase,
        withdrawApprovalUseCase: WithdrawApprovalUseCase
    ) {
        self.documentId = documentId
        self.fetchApprovalDetailUseCase = fetchApprovalDetailUseCase
        self.decideApprovalUseCase = decideApprovalUseCase
        self.addApprovalCommentUseCase = addApprovalCommentUseCase
        self.withdrawApprovalUseCase = withdrawApprovalUseCase
    }

    var detail: ApprovalDetail? {
        state.value
    }

    /// 05-4 "방금 요청 · 결재선 1/3"
    var reviewMeta: String {
        guard let detail else { return "" }
        return "\(TSFormat.relative(detail.item.updatedAt)) 요청 · 결재선 \(detail.currentStep)/\(detail.approvers.count)"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchApprovalDetailUseCase.execute(documentId: documentId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "approval.detail")
            if state.value == nil { state = .failed(error) }
        }
    }

    // MARK: 05-9 승인 · 05-8 반려

    func approve() async {
        await decide(.approve, comment: commentDraft)
    }

    func reject() async {
        await decide(.reject, comment: rejectReason)
    }

    private func decide(_ decision: ApprovalDecision, comment: String) async {
        guard let approvalId = detail?.myApprovalId, !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            _ = try await decideApprovalUseCase.execute(approvalId: approvalId, decision: decision, comment: comment)
            commentDraft = ""
            rejectReason = ""
            dialog = .completed(decision)
            await load()
        } catch {
            dialog = nil
            AppLog.record(error, context: "approval.decide")
            toastMessage = error.userMessage
        }
    }

    // MARK: 의견 · 요청 취소

    func sendComment() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            _ = try await addApprovalCommentUseCase.execute(documentId: documentId, body: commentDraft)
            commentDraft = ""
            toastMessage = "의견을 남겼어요."
            await load()
        } catch {
            AppLog.record(error, context: "approval.comment")
            toastMessage = error.userMessage
        }
    }

    func withdraw() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await withdrawApprovalUseCase.execute(documentId: documentId)
            didWithdraw = true
        } catch {
            AppLog.record(error, context: "approval.withdraw")
            toastMessage = error.userMessage
        }
    }
}
