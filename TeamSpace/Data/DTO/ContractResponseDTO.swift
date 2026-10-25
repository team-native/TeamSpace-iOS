import Foundation

/// GET /finance/contracts 응답의 `data`
/// 명세서에 재무 API 가 없어 Figma 04-2 · 04-3 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ContractLedgerResponseDTO: Decodable {
    let year: Int
    let totalAmount: Int
    let list: [FinanceContractDTO]

    func toEntity() -> ContractLedger {
        ContractLedger(year: year, totalAmount: totalAmount, contracts: list.map { $0.toEntity() })
    }
}

struct FinanceContractDTO: Decodable {
    let id: Int
    let name: String
    let title: String
    let amount: Int
    let collectedAt: Date
    let status: CollectionStatus

    func toEntity() -> FinanceContract {
        FinanceContract(id: id, name: name, title: title, amount: amount, collectedAt: collectedAt, status: status)
    }
}

/// GET /finance/contracts/{contractId} 응답의 `data`
struct ContractDetailResponseDTO: Decodable {
    let contract: FinanceContractDTO
    let category: String
    let clientName: String
    let amountNote: String
    let steps: [ContractStepDTO]
    let pools: [FinancePoolDTO]
    let managerName: String
    let memberCount: Int
    let documentName: String?

    func toEntity() -> ContractDetail {
        ContractDetail(
            contract: contract.toEntity(),
            category: category,
            clientName: clientName,
            amountNote: amountNote,
            steps: steps.map { $0.toEntity() },
            pools: pools.map { $0.toEntity() },
            managerName: managerName,
            memberCount: memberCount,
            documentName: documentName
        )
    }
}

struct ContractStepDTO: Decodable {
    let id: Int
    let title: String
    let date: Date?
    let note: String
    let isDone: Bool

    func toEntity() -> ContractStep {
        ContractStep(id: id, title: title, date: date, note: note, isDone: isDone)
    }
}
