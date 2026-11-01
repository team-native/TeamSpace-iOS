import Foundation

/// 05-5 · 05-6 임시 저장 · 결재 요청 제출
struct SubmitDocumentUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    /// 임시 저장 — 제목만 있으면 저장할 수 있어요.
    func saveDraft(_ draft: DocumentDraft) async throws -> Int {
        guard !draft.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AppError.invalidInput("요청 내용을 입력해 주세요.")
        }
        return try await approvalRepository.createDocument(draft)
    }

    /// 작성 → 제출. 필수 항목이 비어 있으면 제출하지 않아요.
    func submit(_ draft: DocumentDraft) async throws -> Int {
        if let message = Self.validationMessage(for: draft) {
            throw AppError.invalidInput(message)
        }
        let documentId = try await approvalRepository.createDocument(draft)
        try await approvalRepository.submitDocument(documentId: documentId)
        return documentId
    }

    static func validationMessage(for draft: DocumentDraft) -> String? {
        if draft.title.trimmingCharacters(in: .whitespaces).isEmpty { return "요청 내용을 입력해 주세요." }
        if draft.kind == .expense, (draft.amount ?? 0) <= 0 { return "요청 금액을 입력해 주세요." }
        if draft.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "요청 사유를 입력해 주세요." }
        return nil
    }
}
