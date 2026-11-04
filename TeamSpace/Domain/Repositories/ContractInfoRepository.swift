import Foundation

/// 계약 정보 쓰기 [FA · Admin] — /admin/finance/contracts
protocol ContractInfoRepository: Sendable {
    /// POST /admin/finance/contracts — 프로젝트마다 하나 (이미 있으면 409)
    func create(project: String, _ draft: ContractInfoDraft) async throws
    /// PATCH /admin/finance/contracts/{project} — 바뀐 값만
    func update(project: String, changes: ContractInfoChanges) async throws
}

/// PATCH 에 실을 바뀐 값
struct ContractInfoChanges: Equatable, Sendable {
    var pm: String?
    var signed: String?
    var total: Int?
    var collected: Int?
    var step: Int?
    var staff: String?
    var split: String?
    var next: String?

    var isEmpty: Bool {
        pm == nil && signed == nil && total == nil && collected == nil && step == nil && staff == nil && split == nil && next == nil
    }
}
