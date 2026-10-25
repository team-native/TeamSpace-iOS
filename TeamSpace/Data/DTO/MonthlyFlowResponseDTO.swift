import Foundation

/// GET /finance/flows 응답의 `data`
/// 명세서에 재무 API 가 없어 Figma 04-5 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct MonthlyFlowListResponseDTO: Decodable {
    let list: [MonthlyFlowDTO]
}

struct MonthlyFlowDTO: Decodable {
    let month: Date
    let income: Int
    let expense: Int

    func toEntity() -> MonthlyFlow {
        MonthlyFlow(month: month, income: income, expense: expense)
    }
}
