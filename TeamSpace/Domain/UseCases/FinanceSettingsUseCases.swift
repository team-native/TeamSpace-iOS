import Foundation

/// 재무 요약 설정 불러오기 — 아직 설정이 없으면 서버 기본 풀(60 · 30 · 10)을 보여줘요.
struct FetchFinanceSettingsUseCase {
    private let financeSettingsRepository: FinanceSettingsRepository

    init(financeSettingsRepository: FinanceSettingsRepository) {
        self.financeSettingsRepository = financeSettingsRepository
    }

    func execute(user: AuthUser) async throws -> [FinanceSettingsPool] {
        guard user.can(.manageReceipts) else { throw AppError.forbidden("재무 설정은 FA · 관리자만 바꿀 수 있어요.") }
        let pools = try await financeSettingsRepository.fetchPools()
        return pools.isEmpty ? FinanceSettingsPool.defaults : pools
    }
}

/// 풀 금액 · 배분 비율 저장 — 비율 합 100%, 금액은 0 이상
struct SaveFinanceSettingsUseCase {
    private let financeSettingsRepository: FinanceSettingsRepository

    init(financeSettingsRepository: FinanceSettingsRepository) {
        self.financeSettingsRepository = financeSettingsRepository
    }

    func execute(_ pools: [FinanceSettingsPool], user: AuthUser) async throws -> [FinanceSettingsPool] {
        guard user.can(.manageReceipts) else { throw AppError.forbidden("재무 설정은 FA · 관리자만 바꿀 수 있어요.") }
        guard !pools.isEmpty else { throw AppError.invalidInput("풀이 하나 이상 있어야 해요.") }
        guard pools.allSatisfy({ $0.amount >= 0 && $0.ratio >= 0 }) else { throw AppError.invalidInput("금액과 비율은 0 이상이어야 해요.") }
        let ratio = pools.reduce(0) { $0 + $1.ratio }
        guard ratio == 100 else { throw AppError.invalidInput("배분 비율의 합이 100%가 되게 해 주세요. (지금 \(ratio)%)") }
        return try await financeSettingsRepository.savePools(pools)
    }
}
