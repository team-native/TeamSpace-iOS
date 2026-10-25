import Foundation

/// 수금 상태
enum CollectionStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case collected = "COLLECTED"
    case scheduled = "SCHEDULED"
    case unknown = "UNKNOWN"

    static let unknownCase: CollectionStatus = .unknown
}

/// 04-3 수금 내역 한 줄
struct FinanceContract: Equatable, Identifiable, Sendable {
    let id: Int
    /// 클라이언트 · 프로젝트 이름 (예: BRIDGE)
    let name: String
    /// 예) iOS 앱 프로토타입
    let title: String
    let amount: Int
    /// 입금(예정)일
    let collectedAt: Date
    let status: CollectionStatus
}

/// GET /finance/contracts?year=2026
struct ContractLedger: Equatable, Sendable {
    let year: Int
    /// 그해 누적 수주 금액
    let totalAmount: Int
    let contracts: [FinanceContract]
}

/// 04-2 진행 단계 (계약 → 착수 → 납품 → 입금)
struct ContractStep: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let date: Date?
    /// 예) 계약서 서명
    let note: String
    let isDone: Bool
}

/// GET /finance/contracts/{contractId}
struct ContractDetail: Equatable, Sendable {
    let contract: FinanceContract
    /// 예) 외주
    let category: String
    /// 예) 클라이언트 브릿지랩스
    let clientName: String
    /// 예) 부가세 별도
    let amountNote: String
    let steps: [ContractStep]
    let pools: [FinancePool]
    let managerName: String
    let memberCount: Int
    let documentName: String?
}

/// 월별로 묶은 수금 내역
struct ContractMonthGroup: Equatable, Identifiable, Sendable {
    let id: String
    let month: Date
    let contracts: [FinanceContract]
}
