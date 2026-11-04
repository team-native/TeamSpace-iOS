import Foundation

/// 불러온 은행 거래 — FA · Admin 만. 최근 거래가 먼저
struct FetchBankImportsUseCase {
    private let bankImportRepository: BankImportRepository

    init(bankImportRepository: BankImportRepository) {
        self.bankImportRepository = bankImportRepository
    }

    func execute(user: AuthUser) async throws -> [BankImport] {
        guard user.can(.manageBankImports) else { throw AppError.forbidden("은행 거래는 FA · 관리자만 관리할 수 있어요.") }
        return try await bankImportRepository.fetchImports().sorted { $0.date > $1.date }
    }
}

/// 은행 거래 확인 · 확인 취소 · 제외 — 반영된 거래는 바꿀 수 없어요.
struct ReviewBankImportUseCase {
    enum Action: Sendable {
        case confirm
        case unconfirm
        case exclude
    }

    private let bankImportRepository: BankImportRepository

    init(bankImportRepository: BankImportRepository) {
        self.bankImportRepository = bankImportRepository
    }

    func execute(_ item: BankImport, action: Action, user: AuthUser) async throws -> BankImport {
        guard user.can(.manageBankImports) else { throw AppError.forbidden("은행 거래는 FA · 관리자만 관리할 수 있어요.") }
        guard item.status != .committed else { throw AppError.invalidInput("이미 재정에 반영된 거래예요.") }
        switch action {
        case .confirm:
            guard item.canConfirm else {
                throw AppError.invalidInput("연결된 수주 계약이 없는 입금이에요. 웹에서 계약을 연결하거나 제외해 주세요.")
            }
        case .unconfirm:
            guard item.status == .confirmed else { return item }
        case .exclude:
            guard item.status != .excluded else { return item }
        }
        let result = try await bankImportRepository.review(id: item.id, confirm: action == .confirm, exclude: action == .exclude)
        var updated = item
        updated.status = result.status
        updated.matchedProject = result.matchedProject ?? item.matchedProject
        return updated
    }
}

/// 확인 완료 거래를 재정에 반영 — 입금은 수금, 출금은 지출로 들어가요.
struct CommitBankImportsUseCase {
    private let bankImportRepository: BankImportRepository

    init(bankImportRepository: BankImportRepository) {
        self.bankImportRepository = bankImportRepository
    }

    func execute(_ items: [BankImport], user: AuthUser) async throws -> BankImportCommitResult {
        guard user.can(.manageBankImports) else { throw AppError.forbidden("은행 거래는 FA · 관리자만 관리할 수 있어요.") }
        let rowIds = items.filter { $0.status == .confirmed }.map(\.id)
        guard !rowIds.isEmpty else { throw AppError.invalidInput("반영할 확인 완료 거래가 없어요.") }
        return try await bankImportRepository.commit(rowIds: rowIds)
    }
}
