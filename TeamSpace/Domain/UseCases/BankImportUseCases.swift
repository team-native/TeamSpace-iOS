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
    enum Action: Equatable, Sendable {
        case confirm
        case unconfirm
        case exclude
        /// 입금을 수주 계약(프로젝트 이름)에 연결 — 확인은 따로 해요.
        case link(String)
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
                throw AppError.invalidInput("연결된 수주 계약이 없는 입금이에요. 계약을 연결하거나 제외해 주세요.")
            }
        case .unconfirm:
            guard item.status == .confirmed else { return item }
        case .exclude:
            guard item.status != .excluded else { return item }
        case .link(let project):
            guard item.direction == .inbound else { throw AppError.invalidInput("출금 거래는 수주 계약에 연결할 수 없어요.") }
            guard item.status.isOpen else { throw AppError.invalidInput("확인 전 거래만 연결을 바꿀 수 있어요.") }
            guard !project.trimmingCharacters(in: .whitespaces).isEmpty else { throw AppError.invalidInput("연결할 계약을 골라 주세요.") }
        }
        var linkProject: String?
        if case .link(let project) = action { linkProject = project }
        let result = try await bankImportRepository.review(
            id: item.id, confirm: action == .confirm, exclude: action == .exclude, matchedProject: linkProject
        )
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

/// 계좌 연동 상태 [FA · Admin]
struct FetchBankAccountUseCase {
    private let bankImportRepository: BankImportRepository

    init(bankImportRepository: BankImportRepository) {
        self.bankImportRepository = bankImportRepository
    }

    func execute(user: AuthUser) async throws -> BankAccountStatus {
        guard user.can(.manageBankImports) else { throw AppError.forbidden("은행 거래는 FA · 관리자만 관리할 수 있어요.") }
        return try await bankImportRepository.fetchAccount()
    }
}

/// 은행에서 새 거래 불러오기 — 서버는 Admin · FA 만 허용해요.
struct SyncBankTransactionsUseCase {
    private let bankImportRepository: BankImportRepository

    init(bankImportRepository: BankImportRepository) {
        self.bankImportRepository = bankImportRepository
    }

    func execute(user: AuthUser) async throws -> BankSyncResult {
        guard user.can(.manageBankImports) else { throw AppError.forbidden("은행 거래는 FA · 관리자만 관리할 수 있어요.") }
        return try await bankImportRepository.sync()
    }
}

/// 입금을 연결할 수주 계약 — 올해 · 작년 수금 내역의 프로젝트 이름 (서버는 계약의 `project` 로 찾아요)
struct FetchLinkableContractsUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    func execute(now: Date = Date(), calendar: Calendar = .current) async throws -> [String] {
        let year = calendar.component(.year, from: now)
        var names: [String] = []
        for target in [year, year - 1] {
            let contracts = try await financeRepository.fetchContracts(year: target).contracts
            for contract in contracts.sorted(by: { $0.collectedAt > $1.collectedAt }) where !names.contains(contract.title) {
                if !contract.title.isEmpty { names.append(contract.title) }
            }
        }
        return names
    }
}
