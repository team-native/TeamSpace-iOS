import Foundation
import Observation

/// 12-2b 운영 제안 상세 — 추천 · 댓글
@Observable
@MainActor
final class ProposalDetailViewModel {
    private(set) var state: ViewState<ProposalDetail> = .idle
    private(set) var isRecommending = false
    private(set) var isSendingComment = false
    var commentText = ""
    var isCommentAnonymous = false
    var errorMessage: String?

    private let proposalId: Int
    private let fetchProposalDetailUseCase: FetchProposalDetailUseCase
    private let toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase
    private let addProposalCommentUseCase: AddProposalCommentUseCase

    init(
        proposalId: Int,
        fetchProposalDetailUseCase: FetchProposalDetailUseCase,
        toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase,
        addProposalCommentUseCase: AddProposalCommentUseCase
    ) {
        self.proposalId = proposalId
        self.fetchProposalDetailUseCase = fetchProposalDetailUseCase
        self.toggleProposalRecommendUseCase = toggleProposalRecommendUseCase
        self.addProposalCommentUseCase = addProposalCommentUseCase
    }

    var detail: ProposalDetail? { state.value }

    var canSendComment: Bool {
        !isSendingComment && !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 추천 버튼 아래 안내
    var recommendNote: String {
        guard let detail = detail else { return "" }
        return detail.isRecommended
            ? "추천했어요. 다시 누르면 취소돼요. 현재 \(detail.proposal.recommendCount)에는 내 추천 1회가 포함돼요."
            : "1인 1회 추천할 수 있어요. 추천수와 관계없이 담당자가 검토 상태를 바꿔요."
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchProposalDetailUseCase.execute(id: proposalId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "proposal.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func toggleRecommend() async {
        guard let detail = detail, !isRecommending else { return }
        isRecommending = true
        defer { isRecommending = false }
        do {
            state = .loaded(try await toggleProposalRecommendUseCase.execute(detail))
        } catch {
            AppLog.record(error, context: "proposal.recommend")
            errorMessage = error.userMessage
        }
    }

    func sendComment() async {
        guard let detail = detail, canSendComment else { return }
        isSendingComment = true
        defer { isSendingComment = false }
        do {
            state = .loaded(try await addProposalCommentUseCase.execute(detail, body: commentText, isAnonymous: isCommentAnonymous))
            commentText = ""
        } catch {
            AppLog.record(error, context: "proposal.comment")
            errorMessage = error.userMessage
        }
    }
}
