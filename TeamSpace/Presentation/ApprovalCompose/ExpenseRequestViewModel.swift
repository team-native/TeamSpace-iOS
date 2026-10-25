import Foundation
import Observation

/// 05-5 비용 승인 요청
@Observable
@MainActor
final class ExpenseRequestViewModel {
    var expenseType: ExpenseType?
    var project = ""
    var content = ""
    /// 숫자만 입력 (콤마는 화면에서 붙여요)
    var amountText = ""
    var useDate: Date
    var reason = ""
    private(set) var attachmentNames: [String] = []
    var isDatePickerPresented = false
    var isFileImporterPresented = false
    private(set) var isSubmitting = false
    var errorMessage: String?

    private let submitDocumentUseCase: SubmitDocumentUseCase

    init(submitDocumentUseCase: SubmitDocumentUseCase, now: Date = Date()) {
        self.submitDocumentUseCase = submitDocumentUseCase
        self.useDate = now
    }

    var amount: Int {
        Int(amountText.filter(\.isNumber)) ?? 0
    }

    /// 입력하는 동안 "420,000" 처럼 보여줘요.
    var formattedAmount: String {
        amount == 0 ? "" : TSFormat.number(amount)
    }

    var canSubmit: Bool {
        expenseType != nil && !content.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    func updateAmount(_ text: String) {
        amountText = String(text.filter(\.isNumber).prefix(10))
    }

    func addAttachment(named name: String) {
        guard !attachmentNames.contains(name) else { return }
        attachmentNames.append(name)
    }

    func removeAttachment(named name: String) {
        attachmentNames.removeAll { $0 == name }
    }

    var draft: DocumentDraft {
        var fields = [ApprovalField]()
        if let expenseType { fields.append(ApprovalField(title: "비용 유형", value: expenseType.rawValue)) }
        if !project.isEmpty { fields.append(ApprovalField(title: "프로젝트", value: project)) }
        fields.append(ApprovalField(title: "사용 예정일", value: TSFormat.fullDate(useDate)))
        return DocumentDraft(
            kind: .expense,
            title: content.trimmingCharacters(in: .whitespaces),
            amount: amount,
            fields: fields,
            reason: reason,
            attachmentNames: attachmentNames
        )
    }

    /// 결재 요청 제출 → 05-7
    func submit() async -> SubmittedDocument? {
        await run { try await self.submitDocumentUseCase.submit(self.draft) }
    }

    /// 임시 저장 → 내가 올린 결재의 '작성 중'
    func saveDraft() async -> Bool {
        await run { try await self.submitDocumentUseCase.saveDraft(self.draft) } != nil
    }

    private func run(_ work: () async throws -> Int) async -> SubmittedDocument? {
        guard !isSubmitting else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let id = try await work()
            return SubmittedDocument(documentId: id, firstApproverName: ApprovalLinePreview.defaultLine.first?.name ?? "")
        } catch {
            AppLog.record(error, context: "approval.expense")
            errorMessage = error.userMessage
            return nil
        }
    }
}
