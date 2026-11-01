import Foundation

/// GET /finance/overview 응답의 `data`
/// 명세서에 재무 API 가 없어 Figma 04-1 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct FinanceOverviewResponseDTO: Decodable {
    let month: Date
    let collectedAmount: Int
    let isDemo: Bool?
    let pools: [FinancePoolDTO]
    let availableAmount: Int
    let changeRate: Double
    let income: FinanceFlowDTO
    let expense: FinanceFlowDTO
    let updatedAt: Date

    func toEntity() -> FinanceOverview {
        FinanceOverview(
            month: month,
            collectedAmount: collectedAmount,
            isDemo: isDemo ?? false,
            pools: pools.map { $0.toEntity() },
            availableAmount: availableAmount,
            changeRate: changeRate,
            income: income.toEntity(),
            expense: expense.toEntity(),
            updatedAt: updatedAt
        )
    }
}

struct FinanceFlowDTO: Decodable {
    let amount: Int
    let note: String

    func toEntity() -> FinanceFlow {
        FinanceFlow(amount: amount, note: note)
    }
}

/// 재무 API 의 month 파라미터 (yyyy-MM)
enum FinanceMonthParameter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}
