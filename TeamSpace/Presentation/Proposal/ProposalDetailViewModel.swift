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
    /// 더보기 · 고치기 · 지우기
    var isMorePresented = false
    var isDeleteConfirmPresented = false
    /// 고치는 중인 내용 (시트)
    var editDraft: ProposalDraft?
    private(set) var isSavingEdit = false
    private(set) var isDeleted = false

    private let proposalId: Int
    private let fetchProposalDetailUseCase: FetchProposalDetailUseCase
    private let toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase
    private let addProposalCommentUseCase: AddProposalCommentUseCase
    private let user: AuthUser?
    private let fetchProfileUseCase: FetchProfileUseCase?
    private let manageProposalUseCase: ManageProposalUseCase?
    private let editProposalUseCase: EditProposalUseCase?

    init(
        proposalId: Int,
        fetchProposalDetailUseCase: FetchProposalDetailUseCase,
        toggleProposalRecommendUseCase: ToggleProposalRecommendUseCase,
        addProposalCommentUseCase: AddProposalCommentUseCase,
        user: AuthUser? = nil,
        fetchProfileUseCase: FetchProfileUseCase? = nil,
        manageProposalUseCase: ManageProposalUseCase? = nil,
        editProposalUseCase: EditProposalUseCase? = nil
    ) {
        self.editProposalUseCase = editProposalUseCase
        self.proposalId = proposalId
        self.fetchProposalDetailUseCase = fetchProposalDetailUseCase
        self.toggleProposalRecommendUseCase = toggleProposalRecommendUseCase
        self.addProposalCommentUseCase = addProposalCommentUseCase
        self.user = user
        self.fetchProfileUseCase = fetchProfileUseCase
        self.manageProposalUseCase = manageProposalUseCase
    }

    var detail: ProposalDetail? { state.value }

    /// 내 제안이고 접수 상태일 때만 고칠 수 있어요.
    var canEdit: Bool {
        guard editProposalUseCase != nil, let detail else { return false }
        return EditProposalUseCase.canEdit(detail.proposal)
    }

    /// 내 제안 · Admin 은 지울 수 있어요.
    var canDelete: Bool {
        guard editProposalUseCase != nil, let detail else { return false }
        return EditProposalUseCase.canDelete(detail.proposal, user: user)
    }

    var hasMoreMenu: Bool { canEdit || canDelete }

    var canSaveEdit: Bool {
        guard let editDraft, !isSavingEdit else { return false }
        let title = editDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = editDraft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && !body.isEmpty
            && editDraft.title.count <= ProposalDraft.titleLimit && editDraft.body.count <= ProposalDraft.bodyLimit
    }

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

    // MARK: 내 제안 고치기 · 지우기

    func startEditing() {
        guard let detail, canEdit else { return }
        editDraft = EditProposalUseCase.draft(from: detail)
    }

    func saveEdit() async {
        guard let detail, let editDraft, canSaveEdit, let editProposalUseCase else { return }
        isSavingEdit = true
        defer { isSavingEdit = false }
        do {
            state = .loaded(try await editProposalUseCase.update(detail, draft: editDraft))
            self.editDraft = nil
            toastMessage = "제안을 고쳤어요"
        } catch {
            AppLog.record(error, context: "proposal.update")
            errorMessage = error.userMessage
        }
    }

    func delete() async {
        guard let detail, let editProposalUseCase else { return }
        do {
            try await editProposalUseCase.delete(detail.proposal, user: user)
            isDeleted = true
        } catch {
            AppLog.record(error, context: "proposal.delete")
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
