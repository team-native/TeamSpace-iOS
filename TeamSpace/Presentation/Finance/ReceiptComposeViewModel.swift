import Foundation
import Observation

/// 수금 등록 · 수정 [FA · Admin]
@Observable
@MainActor
final class ReceiptComposeViewModel {
    var draft: ReceiptDraft
    private(set) var isSaving = false
    var didSave = false
    private(set) var savedId: Int?
    var errorMessage: String?

    private let user: AuthUser
    private let editingId: Int?
    private let original: ReceiptDraft?
    private let saveReceiptUseCase: SaveReceiptUseCase

    init(user: AuthUser, editing contract: FinanceContract? = nil, saveReceiptUseCase: SaveReceiptUseCase) {
        self.user = user
        self.editingId = contract?.id
        let original = contract.map(ReceiptDraft.init)
        self.original = original
        self.draft = original ?? ReceiptDraft()
        self.saveReceiptUseCase = saveReceiptUseCase
    }

    var isEditing: Bool { editingId != nil }
    var screenTitle: String { isEditing ? "수금 수정" : "수금 등록" }
    var submitTitle: String { isEditing ? "수정하기" : "등록하기" }
    var completionTitle: String { isEditing ? "수금 내역을 고쳤어요" : "수금 내역을 등록했어요" }

    var hasChanges: Bool {
        guard let original else { return true }
        return draft.client != original.client || draft.project != original.project
            || draft.amount != original.amount || draft.status != original.status
            || draft.dayText() != original.dayText()
    }

    var canSubmit: Bool { !isSaving && draft.isValid && hasChanges }

    /// "3,600,000원"
    var amountPreview: String? { draft.amount.map(TSFormat.won) }

    func submit() async {
        guard canSubmit else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            savedId = try await saveReceiptUseCase.execute(draft, original: original, id: editingId, user: user)
            didSave = true
        } catch {
            AppLog.record(error, context: "finance.receipt.save")
            errorMessage = error.userMessage
        }
    }
}
