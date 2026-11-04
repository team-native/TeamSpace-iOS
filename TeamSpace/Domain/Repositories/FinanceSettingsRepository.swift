import Foundation

/// 재무 요약 설정 [FA · Admin] — /admin/finance/settings
protocol FinanceSettingsRepository: Sendable {
    /// 설정이 아직 없으면 빈 배열
    func fetchPools() async throws -> [FinanceSettingsPool]
    /// PATCH — pools 만 보내요. (flow · notices 는 그대로)
    func savePools(_ pools: [FinanceSettingsPool]) async throws -> [FinanceSettingsPool]
}
