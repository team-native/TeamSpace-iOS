import Foundation

/// 은행 거래 확인 · 반영 [FA · Admin] — /finance/bank-imports
protocol BankImportRepository: Sendable {
    func fetchImports() async throws -> [BankImport]
    /// 확인(confirm) · 확인 취소 · 제외(exclude) — 바뀐 상태와 연결 프로젝트를 돌려줘요.
    func review(id: String, confirm: Bool, exclude: Bool) async throws -> (status: BankImport.Status, matchedProject: String?)
    func commit(rowIds: [String]) async throws -> BankImportCommitResult
}
