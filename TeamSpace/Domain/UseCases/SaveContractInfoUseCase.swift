import Foundation

/// 계약 정보 등록 · 수정 — FA · Admin 만. 수정은 바뀐 값만 보내요.
struct SaveContractInfoUseCase {
    private let contractInfoRepository: ContractInfoRepository

    init(contractInfoRepository: ContractInfoRepository) {
        self.contractInfoRepository = contractInfoRepository
    }

    func execute(project: String, draft: ContractInfoDraft, original: ContractInfoDraft?, user: AuthUser) async throws {
        guard user.can(.manageReceipts) else { throw AppError.forbidden("계약 정보는 FA · 관리자만 고칠 수 있어요.") }
        guard !project.trimmingCharacters(in: .whitespaces).isEmpty else { throw AppError.invalidInput("프로젝트 이름이 없는 수금이에요.") }
        guard let total = draft.total, total > 0 else { throw AppError.invalidInput("계약 금액을 입력해 주세요.") }
        if let collected = draft.collected, collected > total {
            throw AppError.invalidInput("받은 금액이 계약 금액보다 커요.")
        }
        if let ratio = draft.splitTotal, ratio != 100 {
            throw AppError.invalidInput("풀 배분 비율의 합이 100%가 되게 해 주세요. (지금 \(ratio)%)")
        }
        guard let original else {
            try await contractInfoRepository.create(project: project, draft)
            return
        }
        var changes = ContractInfoChanges()
        if draft.pm != original.pm { changes.pm = draft.pm }
        if draft.signedText() != original.signedText() { changes.signed = draft.signedText() }
        if draft.total != original.total { changes.total = total }
        if draft.collected != original.collected { changes.collected = draft.collected ?? 0 }
        if draft.step != original.step { changes.step = draft.step }
        if draft.staff != original.staff { changes.staff = draft.staff }
        if draft.split != original.split { changes.split = draft.split }
        if draft.next != original.next { changes.next = draft.next }
        guard !changes.isEmpty else { throw AppError.invalidInput("바뀐 내용이 없어요.") }
        try await contractInfoRepository.update(project: project, changes: changes)
    }
}
