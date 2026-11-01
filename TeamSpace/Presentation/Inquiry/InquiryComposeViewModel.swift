import Foundation
import Observation

/// 11-2 문의 · 건의 작성 → 11-3 접수 알림
@Observable
@MainActor
final class InquiryComposeViewModel {
    var draft = InquiryDraft()
    private(set) var isSubmitting = false
    /// 11-3 — 접수된 문의
    var submitted: InquirySummary?
    var errorMessage: String?

    private let submitInquiryUseCase: SubmitInquiryUseCase

    init(context: InquiryComposeContext, submitInquiryUseCase: SubmitInquiryUseCase) {
        self.submitInquiryUseCase = submitInquiryUseCase
        if let department = context.department { draft.department = department }
        draft.title = context.title ?? ""
        draft.followUpOf = context.followUpOf
    }

    var isFollowUp: Bool { draft.followUpOf != nil }

    var authorNotice: String {
        draft.isAnonymous
            ? "익명 문의는 일반 사용자에게 작성자 정보를 공개하지 않아요."
            : "실명 문의는 담당 부서가 이름과 소속을 함께 확인해요."
    }

    /// "120 / 2,000"
    var bodyCountText: String {
        "\(TSFormat.number(draft.body.count)) / \(TSFormat.number(InquiryDraft.bodyLimit))"
    }

    var submitTitle: String { draft.isAnonymous ? "익명으로 문의 제출" : "실명으로 문의 제출" }

    var canSubmit: Bool {
        !isSubmitting
            && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.title.count <= InquiryDraft.titleLimit
            && draft.body.count <= InquiryDraft.bodyLimit
    }

    /// 11-3 "NativeOps가 검토 후 답변하면 알림으로 알려드려요."
    var submittedMessage: String {
        guard let inquiry = submitted else { return "" }
        return "\(inquiry.department.title)가 검토 후 답변하면 알림으로 알려드려요."
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            submitted = try await submitInquiryUseCase.execute(draft)
        } catch {
            AppLog.record(error, context: "inquiry.submit")
            errorMessage = error.userMessage
        }
    }
}
