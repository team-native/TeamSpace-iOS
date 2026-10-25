import Foundation

/// 재무 API 가짜 응답 — Figma 04 재무 예시 내용
/// 고른 달마다 숫자가 조금씩 달라지게 만들어 기간 선택(04-4)을 확인할 수 있게 합니다.
enum MockFinanceFixture {
    /// 달마다 다른 배수 (10월 = 1.0 → Figma 숫자 그대로)
    static func scale(for month: Date, calendar: Calendar = .current) -> Double {
        let value = calendar.component(.month, from: month)
        return 1.0 - Double((10 - value + 12) % 12) * 0.06
    }

    static func overview(monthText: String?, now: Date = Date()) -> String {
        let month = monthText.flatMap(FinanceMonthParameter.date(from:)) ?? now
        let ratio = scale(for: month)
        func amount(_ value: Int) -> Int { Int((Double(value) * ratio / 10_000).rounded()) * 10_000 }
        let formatter = ISO8601DateFormatter()
        let collected = amount(8_900_000)
        return """
        {"code":200,"message":"조회 성공","data":{
          "month":"\(formatter.string(from: month))",
          "collectedAmount":\(collected),
          "isDemo":true,
          "pools":[{"kind":"OPERATION","ratio":40,"amount":\(collected * 4 / 10)},
                   {"kind":"RESERVE","ratio":30,"amount":\(collected * 3 / 10)},
                   {"kind":"DIVIDEND","ratio":30,"amount":\(collected * 3 / 10)}],
          "availableAmount":\(collected * 4 / 10),
          "changeRate":\(String(format: "%.1f", 12.8 * ratio)),
          "income":{"amount":\(amount(7_260_000)),"note":"외주 프로젝트 3건"},
          "expense":{"amount":\(amount(3_480_000)),"note":"운영비 포함 8건"},
          "updatedAt":"\(formatter.string(from: now))"
        }}
        """
    }
}
