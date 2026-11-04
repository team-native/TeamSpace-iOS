import Foundation

/// 수금 등록 · 수정 — FA · Admin 만. 수정은 바뀐 값만 보내요.
struct SaveReceiptUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    /// 새 수금 id 또는 고친 수금 id
    func execute(_ draft: ReceiptDraft, original: ReceiptDraft? = nil, id: Int? = nil, user: AuthUser) async throws -> Int {
        guard user.can(.manageReceipts) else { throw AppError.forbidden("수금 내역은 FA · 관리자만 등록할 수 있어요.") }
        guard !draft.client.trimmingCharacters(in: .whitespaces).isEmpty else { throw AppError.invalidInput("클라이언트를 입력해 주세요.") }
        guard !draft.project.trimmingCharacters(in: .whitespaces).isEmpty else { throw AppError.invalidInput("프로젝트를 입력해 주세요.") }
        guard let amount = draft.amount, amount > 0 else { throw AppError.invalidInput("금액을 입력해 주세요.") }
        guard let id, let original else {
            return try await financeRepository.createReceipt(draft)
        }
        var changes = ReceiptChanges()
        if draft.client != original.client { changes.client = draft.client }
        if draft.project != original.project { changes.project = draft.project }
        if amount != original.amount { changes.amount = amount }
        if draft.status != original.status { changes.status = draft.status }
        if draft.dayText() != original.dayText() { changes.date = draft.dayText() }
        guard !changes.isEmpty else { throw AppError.invalidInput("바뀐 내용이 없어요.") }
        try await financeRepository.updateReceipt(id: id, changes: changes)
        return id
    }
}

/// PATCH 에 실을 바뀐 값
struct ReceiptChanges: Equatable, Sendable {
    var client: String?
    var project: String?
    var amount: Int?
    var status: ReceiptStatus?
    var date: String?

    var isEmpty: Bool { client == nil && project == nil && amount == nil && status == nil && date == nil }
}
