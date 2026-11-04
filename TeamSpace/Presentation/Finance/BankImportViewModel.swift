import Foundation
import Observation

/// 은행 거래 확인 · 반영 [FA · Admin] — /finance/bank-imports · /finance/bank-import-commits
@Observable
@MainActor
final class BankImportViewModel {
    enum Filter: String, CaseIterable, Identifiable, Sendable {
        case open = "확인할 거래"
        case confirmed = "반영 대기"
        case done = "끝난 거래"

        var id: String { rawValue }

        func contains(_ item: BankImport) -> Bool {
            switch self {
            case .open: return item.status.isOpen
            case .confirmed: return item.status == .confirmed
            case .done: return item.status == .committed || item.status == .excluded
            }
        }
    }

    private(set) var state: ViewState<[BankImport]> = .idle
    var filter: Filter = .open
    private(set) var processingId: String?
    private(set) var isCommitting = false
    var toastMessage: String?
    var errorMessage: String?
    /// 계좌 연동 상태 — 못 불러와도 거래 목록은 보여줘요.
    private(set) var account: BankAccountStatus?
    private(set) var isSyncing = false
    /// 계약 연결 시트를 연 입금
    var linkingItem: BankImport?
    private(set) var linkableContracts: ViewState<[String]> = .idle

    private let user: AuthUser
    private let fetchBankImportsUseCase: FetchBankImportsUseCase
    private let reviewBankImportUseCase: ReviewBankImportUseCase
    private let commitBankImportsUseCase: CommitBankImportsUseCase
    private let fetchBankAccountUseCase: FetchBankAccountUseCase?
    private let syncBankTransactionsUseCase: SyncBankTransactionsUseCase?
    private let fetchLinkableContractsUseCase: FetchLinkableContractsUseCase?

    init(
        user: AuthUser,
        fetchBankImportsUseCase: FetchBankImportsUseCase,
        reviewBankImportUseCase: ReviewBankImportUseCase,
        commitBankImportsUseCase: CommitBankImportsUseCase,
        fetchBankAccountUseCase: FetchBankAccountUseCase? = nil,
        syncBankTransactionsUseCase: SyncBankTransactionsUseCase? = nil,
        fetchLinkableContractsUseCase: FetchLinkableContractsUseCase? = nil
    ) {
        self.fetchBankAccountUseCase = fetchBankAccountUseCase
        self.syncBankTransactionsUseCase = syncBankTransactionsUseCase
        self.fetchLinkableContractsUseCase = fetchLinkableContractsUseCase
        self.user = user
        self.fetchBankImportsUseCase = fetchBankImportsUseCase
        self.reviewBankImportUseCase = reviewBankImportUseCase
        self.commitBankImportsUseCase = commitBankImportsUseCase
    }

    private var all: [BankImport] { state.value ?? [] }

    var items: [BankImport] { all.filter(filter.contains) }

    func count(_ filter: Filter) -> Int { all.filter(filter.contains).count }

    private var confirmed: [BankImport] { all.filter { $0.status == .confirmed } }

    var canCommit: Bool { !isCommitting && !confirmed.isEmpty }

    /// "확인한 2건 재정에 반영"
    var commitTitle: String { "확인한 \(confirmed.count)건 재정에 반영" }

    /// "입금 1,200,000원 · 출금 54,000원"
    var confirmedTotalText: String {
        let inbound = confirmed.filter { $0.direction == .inbound }.reduce(0) { $0 + $1.amount }
        let outbound = confirmed.filter { $0.direction == .outbound }.reduce(0) { $0 + $1.amount }
        return "입금 \(TSFormat.won(inbound)) · 출금 \(TSFormat.won(outbound))"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchBankImportsUseCase.execute(user: user))
            await loadAccount()
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.bankImports.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func review(_ item: BankImport, _ action: ReviewBankImportUseCase.Action) async {
        guard processingId == nil else { return }
        processingId = item.id
        defer { processingId = nil }
        do {
            let updated = try await reviewBankImportUseCase.execute(item, action: action, user: user)
            replace(updated)
            switch action {
            case .confirm: toastMessage = "확인했어요. 반영 대기로 옮겼어요"
            case .unconfirm: toastMessage = "확인을 취소했어요"
            case .exclude: toastMessage = "반영 대상에서 제외했어요"
            case .link(let project): toastMessage = "\(project)에 연결했어요. 확인을 눌러 주세요"
            }
        } catch {
            AppLog.record(error, context: "finance.bankImports.review")
            errorMessage = error.userMessage
        }
    }

    func commit() async {
        guard canCommit else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            let result = try await commitBankImportsUseCase.execute(all, user: user)
            toastMessage = "\(result.committedCount)건을 재정에 반영했어요 (수금 \(result.receiptCount) · 지출 \(result.expenseCount))"
            await load()
        } catch {
            AppLog.record(error, context: "finance.bankImports.commit")
            errorMessage = error.userMessage
        }
    }

    /// "마지막 불러오기 11.04 13:20 · 이번 달 입금 3 · 출금 2"
    var accountDetailText: String? {
        guard let account else { return nil }
        let last = account.lastSyncedAt.map { "마지막 불러오기 \(TSFormat.dateTime($0))" } ?? "아직 불러온 적 없어요"
        return "\(last) · 이번 달 입금 \(account.inboundCount) · 출금 \(account.outboundCount)"
    }

    /// 3번 넘게 연달아 실패하면 안내해요.
    var failureNotice: String? {
        guard let failures = account?.consecutiveFailures, failures > 0 else { return nil }
        return "최근 불러오기가 \(failures)번 연달아 실패했어요."
    }

    func loadAccount() async {
        guard let fetchBankAccountUseCase else { return }
        do {
            account = try await fetchBankAccountUseCase.execute(user: user)
        } catch {
            AppLog.record(error, context: "finance.bankAccount.load")
        }
    }

    /// 은행에서 새 거래 불러오기 → 목록 · 계좌 상태 새로고침
    func sync() async {
        guard let syncBankTransactionsUseCase, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let result = try await syncBankTransactionsUseCase.execute(user: user)
            toastMessage = result.importedCount > 0 ? "새 거래 \(result.importedCount)건을 불러왔어요" : "새 거래가 없어요"
            await load()
        } catch {
            AppLog.record(error, context: "finance.bankImports.sync")
            errorMessage = error.userMessage
            await loadAccount()
        }
    }

    func startLinking(_ item: BankImport) {
        linkingItem = item
        if linkableContracts.value == nil { Task { await loadLinkableContracts() } }
    }

    func loadLinkableContracts() async {
        guard let fetchLinkableContractsUseCase else { return }
        linkableContracts = .loading
        do {
            let names = try await fetchLinkableContractsUseCase.execute()
            linkableContracts = names.isEmpty ? .empty : .loaded(names)
        } catch {
            AppLog.record(error, context: "finance.bankImports.contracts")
            linkableContracts = .failed(error)
        }
    }

    func link(_ item: BankImport, to project: String) async {
        linkingItem = nil
        await review(item, .link(project))
    }

    private func replace(_ item: BankImport) {
        var items = all
        if let index = items.firstIndex(where: { $0.id == item.id }) { items[index] = item }
        state = .loaded(items)
    }
}

extension BankImport {
    /// "+1,200,000원" · "-54,000원"
    var amountText: String { (direction == .inbound ? "+" : "-") + TSFormat.won(amount) }

    /// 입금인데 연결 계약이 없으면 안내
    var matchText: String {
        if let matchedProject, !matchedProject.isEmpty { return "연결: \(matchedProject)" }
        return direction == .inbound ? "연결된 수주 계약 없음" : "지출로 반영돼요"
    }
}
