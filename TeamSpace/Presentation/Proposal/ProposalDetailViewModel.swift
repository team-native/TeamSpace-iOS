import Foundation
import Observation

/// 12-2b 운영 제안 상세 — 추천 · 댓글 · 12-2c 담당자 처리
@Observable
@MainActor
final class ProposalDetailViewModel {
    private(set) var state: ViewState<ProposalDetail> = .idle
    private(set) var isRecommending = false
    private(set) var isSendingComment = false
    var commentText = ""
    var isCommentAnonymous = false
    var errorMessage: String?
    var toastMessage: String?
    /// 12-2c 담당자 처리
    var manageDraft = ProposalManageDraft()
    private(set) var isManaging = false
    private(set) var department: String?

    private let proposalId: Int
    private let fetchProposalDetailUseCase: FetchProposalDetailUseCase
    private let toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase
    private let addProposalCommentUseCase: AddProposalCommentUseCase
    private let user: AuthUser?
    private let fetchProfileUseCase: FetchProfileUseCase?
    private let manageProposalUseCase: ManageProposalUseCase?

    init(
        proposalId: Int,
        fetchProposalDetailUseCase: FetchProposalDetailUseCase,
        toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase,
        addProposalCommentUseCase: AddProposalCommentUseCase,
        user: AuthUser? = nil,
        fetchProfileUseCase: FetchProfileUseCase? = nil,
        manageProposalUseCase: ManageProposalUseCase? = nil
    ) {
        self.proposalId = proposalId
        self.fetchProposalDetailUseCase = fetchProposalDetailUseCase
        self.toggleProposalRecommendUseCase = toggleProposalRecommendUseCase
        self.addProposalCommentUseCase = addProposalCommentUseCase
        self.user = user
        self.fetchProfileUseCase = fetchProfileUseCase
        self.manageProposalUseCase = manageProposalUseCase
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

    /// Admin 이거나 내 부서가 담당 부서일 때 처리 카드를 보여줘요.
    var canManage: Bool {
        guard manageProposalUseCase != nil, let detail else { return false }
        return ManageProposalUseCase.canManage(detail.proposal, user: user, department: department)
    }

    var canSubmitManage: Bool {
        guard canManage, !isManaging else { return false }
        if manageDraft.action.needsBody {
            return !manageDraft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return manageDraft.action.status != detail?.proposal.status
    }

    func load() async {
        if state.value == nil { state = .loading }
        await loadDepartment()
        do {
            let loaded = try await fetchProposalDetailUseCase.execute(id: proposalId)
            if state.value == nil { manageDraft = ProposalManageDraft(current: loaded.proposal.status) }
            state = .loaded(loaded)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "proposal.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// Admin 이 아니면 프로필의 부서를 한 번 읽어 둬요. (실패하면 카드를 숨겨요)
    private func loadDepartment() async {
        guard department == nil, manageProposalUseCase != nil, let user, !user.roles.contains(.admin),
              let fetchProfileUseCase else { return }
        department = try? await fetchProfileUseCase.execute().department
    }

    func submitManage() async {
        guard let detail, canSubmitManage, let manageProposalUseCase else { return }
        isManaging = true
        defer { isManaging = false }
        let action = manageDraft.action
        do {
            let updated = try await manageProposalUseCase.execute(detail, draft: manageDraft)
            state = .loaded(updated)
            manageDraft = ProposalManageDraft(current: updated.proposal.status)
            switch action {
            case .answer: toastMessage = "공식 답변을 등록했어요"
            case .reject: toastMessage = "반려했어요"
            case .reviewing, .inProgress: toastMessage = "\(action.title)으로 바꿨어요"
            }
        } catch {
            AppLog.record(error, context: "proposal.manage")
            errorMessage = error.userMessage
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
