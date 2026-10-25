import Foundation
import Observation

/// 04-7 재정 제한 권한 — 구성원에게 공개되는 요약과 가려진 정보
@Observable
@MainActor
final class FinanceAccessViewModel {
    private(set) var state: ViewState<ContractLedger> = .idle

    let year: Int
    let user: AuthUser
    private let fetchContractLedgerUseCase: FetchContractLedgerUseCase

    init(year: Int, user: AuthUser, fetchContractLedgerUseCase: FetchContractLedgerUseCase) {
        self.year = year
        self.user = user
        self.fetchContractLedgerUseCase = fetchContractLedgerUseCase
    }

    /// "일반 구성원 · 공개 요약" / "FA · 전체 열람"
    var scopeBadge: String {
        user.can(.viewFinanceDetail) ? "\(user.financeScopeTitle) · 전체 열람" : "일반 구성원 · 공개 요약"
    }

    var canRequestAccess: Bool {
        !user.can(.viewFinanceDetail)
    }

    /// 가장 최근에 수금이 확인된 수주
    var latestCollected: FinanceContract? {
        state.value?.contracts
            .filter { $0.status == .collected }
            .max { $0.collectedAt < $1.collectedAt }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchContractLedgerUseCase.execute(year: year))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.access")
            if state.value == nil { state = .failed(error) }
        }
    }
}
