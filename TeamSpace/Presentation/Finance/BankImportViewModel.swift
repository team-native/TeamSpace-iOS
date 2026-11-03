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

    private let user: AuthUser
    private let fetchBankImportsUseCase: FetchBankImportsUseCase
    private let reviewBankImportUseCase: ReviewBankImportUseCase
    private let commitBankImportsUseCase: CommitBankImportsUseCase

    init(
        user: AuthUser,
        fetchBankImportsUseCase: FetchBankImportsUseCase,
        reviewBankImportUseCase: ReviewBankImportUseCase,
        commitBankImportsUseCase: CommitBankImportsUseCase
    ) {
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
