import Foundation
import Observation

/// 11-6 문의 검토 · 공식 답변 작성 [담당자 운영 화면]
@Observable
@MainActor
final class InquiryReviewViewModel {
    private(set) var state: ViewState<InquiryInboxItem> = .idle
    private(set) var assignees: [String] = []
    private(set) var rules: [RuleSummary] = []
    var draft = InquiryReplyDraft()
    var isPreviewing = false
    private(set) var isSubmitting = false
    var toastMessage: String?
    var errorMessage: String?

    private let inquiryId: Int
    private let user: AuthUser
    private let fetchInquiryReviewUseCase: FetchInquiryReviewUseCase
    private let fetchInquiryInboxUseCase: FetchInquiryInboxUseCase
    private let assignInquiryUseCase: AssignInquiryUseCase
    private let replyInquiryUseCase: ReplyInquiryUseCase
    private let fetchRulesUseCase: FetchRulesUseCase

    init(
        inquiryId: Int,
        user: AuthUser,
        fetchInquiryReviewUseCase: FetchInquiryReviewUseCase,
        fetchInquiryInboxUseCase: FetchInquiryInboxUseCase,
        assignInquiryUseCase: AssignInquiryUseCase,
        replyInquiryUseCase: ReplyInquiryUseCase,
        fetchRulesUseCase: FetchRulesUseCase
    ) {
        self.inquiryId = inquiryId
        self.user = user
        self.fetchInquiryReviewUseCase = fetchInquiryReviewUseCase
        self.fetchInquiryInboxUseCase = fetchInquiryInboxUseCase
        self.assignInquiryUseCase = assignInquiryUseCase
        self.replyInquiryUseCase = replyInquiryUseCase
        self.fetchRulesUseCase = fetchRulesUseCase
    }

    var item: InquiryInboxItem? { state.value }

    /// 답변 · 반려 전이면 고칠 수 있어요.
    var isEditable: Bool { item?.inquiry.status.isOpen ?? false }

    var selectedRule: RuleSummary? {
        draft.referenceRuleId.flatMap { id in rules.first { $0.id == id } }
    }

    /// "검토 중 → 답변 완료"
    var statusChangeText: String {
        "\(item?.inquiry.status.title ?? "") → \(draft.kind.resultStatus.title)"
    }

    var submitTitle: String { draft.kind == .answer ? "공식 답변 등록" : "반려 사유 등록" }

    var canSubmit: Bool {
        isEditable && !isSubmitting && !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.body.count <= InquiryReplyDraft.bodyLimit
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            async let item = fetchInquiryReviewUseCase.execute(id: inquiryId, user: user)
            async let inbox = fetchInquiryInboxUseCase.execute(user: user)
            async let rules = fetchRulesUseCase.execute()
            state = .loaded(try await item)
            assignees = (try? await inbox)?.assignees ?? []
            self.rules = (try? await rules) ?? []
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "inquiry.review.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func assign(_ assignee: String) async {
        guard let item = item else { return }
        do {
            state = .loaded(try await assignInquiryUseCase.execute(item, assignee: assignee))
            toastMessage = "\(assignee) 님을 담당자로 배정했어요"
        } catch {
            AppLog.record(error, context: "inquiry.assign")
            errorMessage = error.userMessage
        }
    }

    func submit() async {
        guard let item = item, canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            state = .loaded(try await replyInquiryUseCase.execute(item, draft: draft))
            toastMessage = draft.kind == .answer ? "공식 답변을 등록했어요" : "반려 사유를 등록했어요"
            isPreviewing = false
        } catch {
            AppLog.record(error, context: "inquiry.reply")
            errorMessage = error.userMessage
        }
    }
}
