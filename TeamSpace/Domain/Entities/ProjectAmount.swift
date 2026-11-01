import Foundation

enum ProjectAmountStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case unknown = "UNKNOWN"

    static let unknownCase: ProjectAmountStatus = .unknown
}

/// 04-9 프로젝트 한 건의 금액
/// 재정 권한이 없으면 서버가 금액을 nil 로 내려줘요. (04-8 금액 가림)
struct ProjectAmount: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let status: ProjectAmountStatus
    let contractAmount: Int?
    let paidAmount: Int?

    var unpaidAmount: Int? {
        guard let contractAmount, let paidAmount else { return nil }
        return max(contractAmount - paidAmount, 0)
    }

    /// 입금률 0~100
    var paidPercent: Int? {
        guard let contractAmount, let paidAmount, contractAmount > 0 else { return nil }
        return Int((Double(paidAmount) / Double(contractAmount) * 100).rounded())
    }
}

/// GET /finance/projects?year=2026
struct ProjectAmountSummary: Equatable, Sendable {
    let year: Int
    /// 올해 수주 건수
    let yearCount: Int
    let totalContractAmount: Int?
    let totalPaidAmount: Int?
    /// 이번 달 신규 수주 건수 · 입금 건수 (권한 없이도 공개)
    let monthNewContracts: Int
    let monthDeposits: Int
    let projects: [ProjectAmount]

    var totalUnpaidAmount: Int? {
        guard let totalContractAmount, let totalPaidAmount else { return nil }
        return max(totalContractAmount - totalPaidAmount, 0)
    }

    /// 서버가 금액을 가려서 보냈는지
    var isMasked: Bool {
        totalContractAmount == nil
    }

    var inProgressCount: Int {
        projects.filter { $0.status == .inProgress }.count
    }
}
