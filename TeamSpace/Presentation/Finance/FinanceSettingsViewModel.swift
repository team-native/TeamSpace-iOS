import Foundation
import Observation

/// 재무 요약 설정 [FA · Admin] — 풀별 지금 금액 · 새 수금 배분 비율
@Observable
@MainActor
final class FinanceSettingsViewModel {
    /// 입력 중인 풀 한 줄
    struct Row: Equatable, Identifiable {
        let pool: FinanceSettingsPool
        var amountText: String
        var ratioText: String

        var id: String { pool.id }

        init(_ pool: FinanceSettingsPool) {
            self.pool = pool
            amountText = String(pool.amount)
            ratioText = String(pool.ratio)
        }

        var amount: Int? { Int(amountText.filter(\.isNumber)) }
        var ratio: Int? { Int(ratioText.filter(\.isNumber)) }

        var edited: FinanceSettingsPool? {
            guard let amount, let ratio else { return nil }
            var pool = pool
            pool.amount = amount
            pool.ratio = ratio
            return pool
        }
    }

    private(set) var state: ViewState<[FinanceSettingsPool]> = .idle
    var rows: [Row] = []
    private(set) var isSaving = false
    var toastMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let fetchFinanceSettingsUseCase: FetchFinanceSettingsUseCase
    private let saveFinanceSettingsUseCase: SaveFinanceSettingsUseCase

    init(user: AuthUser, fetchFinanceSettingsUseCase: FetchFinanceSettingsUseCase, saveFinanceSettingsUseCase: SaveFinanceSettingsUseCase) {
        self.user = user
        self.fetchFinanceSettingsUseCase = fetchFinanceSettingsUseCase
        self.saveFinanceSettingsUseCase = saveFinanceSettingsUseCase
    }

    var ratioTotal: Int { rows.reduce(0) { $0 + ($1.ratio ?? 0) } }

    /// "합계 100%" · "합계 90% — 100%가 되게 해 주세요"
    var ratioText: String {
        ratioTotal == 100 ? "합계 100%" : "합계 \(ratioTotal)% — 100%가 되게 해 주세요"
    }

    /// "모든 풀 9,000,000원"
    var amountTotalText: String {
        "모든 풀 \(TSFormat.won(rows.reduce(0) { $0 + ($1.amount ?? 0) }))"
    }

    var hasChanges: Bool {
        rows.compactMap(\.edited) != (state.value ?? []) || rows.contains { $0.edited == nil }
    }

    var canSave: Bool {
        !isSaving && hasChanges && ratioTotal == 100 && rows.allSatisfy { $0.edited != nil }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let pools = try await fetchFinanceSettingsUseCase.execute(user: user)
            state = .loaded(pools)
            rows = pools.map(Row.init)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.settings.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await saveFinanceSettingsUseCase.execute(rows.compactMap(\.edited), user: user)
            state = .loaded(saved)
            rows = saved.map(Row.init)
            toastMessage = "재무 설정을 저장했어요"
        } catch {
            AppLog.record(error, context: "finance.settings.save")
            errorMessage = error.userMessage
        }
    }

    /// 불러온 값으로 되돌려요.
    func reset() {
        rows = (state.value ?? []).map(Row.init)
    }
}
