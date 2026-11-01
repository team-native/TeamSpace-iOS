import Foundation
import Observation

/// 12-3 운영 제안 쓰기 → 게시 완료 알림 (10-9 와 같은 모양)
@Observable
@MainActor
final class ProposalComposeViewModel {
    var draft = ProposalDraft()
    private(set) var didRestoreDraft = false
    private(set) var isSubmitting = false
    /// 올린 제안 (알림을 띄워요)
    var published: ProposalSummary?
    var errorMessage: String?

    private let createProposalUseCase: CreateProposalUseCase
    private let proposalDraftUseCase: ProposalDraftUseCase

    init(createProposalUseCase: CreateProposalUseCase, proposalDraftUseCase: ProposalDraftUseCase) {
        self.createProposalUseCase = createProposalUseCase
        self.proposalDraftUseCase = proposalDraftUseCase
        if let saved = proposalDraftUseCase.fetch() {
            draft = saved
            didRestoreDraft = true
        }
    }

    var authorNotice: String {
        draft.isAnonymous
            ? "익명으로 올려도 담당 부서 답변과 진행 상태는 그대로 받아볼 수 있어요."
            : "실명으로 올리면 이름이 제안과 함께 보여요."
    }

    /// "96 / 2,000"
    var bodyCountText: String {
        "\(TSFormat.number(draft.body.count)) / \(TSFormat.number(ProposalDraft.bodyLimit))"
    }

    var submitTitle: String { draft.isAnonymous ? "익명으로 제안 올리기" : "실명으로 제안 올리기" }

    var canSubmit: Bool {
        !isSubmitting
            && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.title.count <= ProposalDraft.titleLimit
            && draft.body.count <= ProposalDraft.bodyLimit
    }

    /// 게시 완료 알림 문구
    var completionMessage: String {
        guard let proposal = published else { return "" }
        let who = proposal.isAnonymous ? "익명으로 올라가 작성자는 표시되지 않아요." : "실명으로 올라가 이름이 함께 보여요."
        return "\(who) \(proposal.department)가 검토하면 진행 상태가 바뀌어요."
    }

    /// "임시 저장" — 빈 글이면 저장하지 않아요.
    @discardableResult
    func saveDraft() -> Bool {
        proposalDraftUseCase.save(draft)
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            published = try await createProposalUseCase.execute(draft)
        } catch {
            AppLog.record(error, context: "proposal.create")
            errorMessage = error.userMessage
        }
    }
}
