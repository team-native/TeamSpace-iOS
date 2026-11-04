import Foundation

/// 은행 거래 확인 · 반영 [FA · Admin] — /finance/bank-imports
protocol BankImportRepository: Sendable {
    func fetchImports() async throws -> [BankImport]
    /// 확인(confirm) · 확인 취소 · 제외(exclude) — 바뀐 상태와 연결 프로젝트를 돌려줘요.
    /// matchedProject 를 주면 입금을 그 수주 계약(프로젝트 이름)에 연결해요.
    func review(id: String, confirm: Bool, exclude: Bool, matchedProject: String?) async throws -> (status: BankImport.Status, matchedProject: String?)
    /// GET /finance/bank-accounts
    func fetchAccount() async throws -> BankAccountStatus
    /// POST /finance/bank-syncs — 은행에서 새 거래를 불러와요.
    func sync() async throws -> BankSyncResult
    func commit(rowIds: [String]) async throws -> BankImportCommitResult
}
