import Foundation

/// GET /finance/projects 응답의 `data`
/// 명세서에 재무 API 가 없어 Figma 04-8 · 04-9 기준으로 정했습니다. (백엔드와 맞춰야 함)
/// 재정 권한이 없으면 금액 필드는 null 로 와요.
struct ProjectAmountSummaryResponseDTO: Decodable {
    let year: Int
    let yearCount: Int
    let totalContractAmount: Int?
    let totalPaidAmount: Int?
    let monthNewContracts: Int
    let monthDeposits: Int
    let list: [ProjectAmountDTO]

    func toEntity() -> ProjectAmountSummary {
        ProjectAmountSummary(
            year: year,
            yearCount: yearCount,
            totalContractAmount: totalContractAmount,
            totalPaidAmount: totalPaidAmount,
            monthNewContracts: monthNewContracts,
            monthDeposits: monthDeposits,
            projects: list.map { $0.toEntity() }
        )
    }
}

struct ProjectAmountDTO: Decodable {
    let id: Int
    let name: String
    let status: ProjectAmountStatus
    let contractAmount: Int?
    let paidAmount: Int?

    func toEntity() -> ProjectAmount {
        ProjectAmount(id: id, name: name, status: status, contractAmount: contractAmount, paidAmount: paidAmount)
    }
}
