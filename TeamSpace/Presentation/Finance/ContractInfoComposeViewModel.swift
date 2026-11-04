import Foundation
import Observation

/// 계약 정보 등록 · 수정 [FA · Admin] — 수주 상세에서 열어요.
@Observable
@MainActor
final class ContractInfoComposeViewModel {
    var draft: ContractInfoDraft
    private(set) var isSaving = false
    var didSave = false
    var errorMessage: String?

    /// 수금 내역의 프로젝트 이름 — 서버는 이 이름으로 계약을 찾아요.
    let project: String
    private let user: AuthUser
    private let original: ContractInfoDraft?
    private let saveContractInfoUseCase: SaveContractInfoUseCase

    init(user: AuthUser, detail: ContractDetail, saveContractInfoUseCase: SaveContractInfoUseCase) {
        self.user = user
        self.project = detail.contract.title
        let original = detail.info.map { ContractInfoDraft($0) }
        self.original = original
        var draft = original ?? ContractInfoDraft()
        if original == nil { draft.totalText = String(detail.contract.amount) }
        self.draft = draft
        self.saveContractInfoUseCase = saveContractInfoUseCase
    }

    var isEditing: Bool { original != nil }
    var screenTitle: String { isEditing ? "계약 정보 수정" : "계약 정보 등록" }
    var submitTitle: String { isEditing ? "수정하기" : "등록하기" }
    var completionTitle: String { isEditing ? "계약 정보를 고쳤어요" : "계약 정보를 등록했어요" }

    var hasChanges: Bool { original.map { $0 != draft } ?? true }
    var canSubmit: Bool { !isSaving && (draft.total ?? 0) > 0 && hasChanges }

    /// "합계 100%" · "합계 90% — 100%가 되게 해 주세요"
    var splitText: String? {
        guard let total = draft.splitTotal else { return nil }
        return total == 100 ? "합계 100%" : "합계 \(total)% — 100%가 되게 해 주세요"
    }

    func submit() async {
        guard canSubmit else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await saveContractInfoUseCase.execute(project: project, draft: draft, original: original, user: user)
            didSave = true
        } catch {
            AppLog.record(error, context: "finance.contractInfo.save")
            errorMessage = error.userMessage
        }
    }
}
