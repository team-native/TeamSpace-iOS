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

    // MARK: 04-2 · 04-3 수주 · 수금

    private struct ContractRow {
        let id: Int
        let name: String
        let title: String
        let amount: Int
        let month: Int
        let day: Int
        let isCollected: Bool
    }

    private static let contracts: [ContractRow] = [
        ContractRow(id: 1, name: "BRIDGE", title: "iOS 앱 프로토타입", amount: 3_600_000, month: 10, day: 18, isCollected: true),
        ContractRow(id: 2, name: "MOTION", title: "브랜드 웹 구축", amount: 2_800_000, month: 10, day: 12, isCollected: true),
        ContractRow(id: 3, name: "CAMPUS", title: "관리자 도구 개발", amount: 2_500_000, month: 10, day: 29, isCollected: false),
        ContractRow(id: 4, name: "ORBIT", title: "사내 대시보드", amount: 4_200_000, month: 9, day: 27, isCollected: true),
        ContractRow(id: 5, name: "PLANT", title: "커머스 리뉴얼", amount: 3_100_000, month: 9, day: 14, isCollected: true),
        ContractRow(id: 6, name: "HELLO", title: "온보딩 앱 MVP", amount: 5_000_000, month: 8, day: 30, isCollected: true),
        ContractRow(id: 7, name: "NOTE", title: "노트 앱 디자인", amount: 1_800_000, month: 8, day: 11, isCollected: true)
    ]

    /// 한국 시간 기준 날짜 문자열 (예: 2026-10-18T10:00:00+09:00)
    private static func dateText(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02dT10:00:00+09:00", year, month, day)
    }

    private static func contractJSON(_ row: ContractRow, year: Int) -> String {
        let status = row.isCollected ? "COLLECTED" : "SCHEDULED"
        return """
        {"id":\(row.id),"name":"\(row.name)","title":"\(row.title)","amount":\(row.amount),\
        "collectedAt":"\(dateText(year: year, month: row.month, day: row.day))",\
        "status":"\(status)"}
        """
    }

    static func ledger(yearText: String?, now: Date = Date()) -> String {
        let year = yearText.flatMap(Int.init) ?? Calendar.current.component(.year, from: now)
        let list = contracts.map { contractJSON($0, year: year) }.joined(separator: ",")
        return """
        {"code":200,"message":"조회 성공","data":{"year":\(year),"totalAmount":48300000,"list":[\(list)]}}
        """
    }

    static func contractDetail(id: Int, now: Date = Date()) -> String? {
        guard let row = contracts.first(where: { $0.id == id }) else { return nil }
        let year = Calendar.current.component(.year, from: now)
        let steps = [
            ("계약", 9, 2, "계약서 서명", true),
            ("착수", 9, 5, "킥오프 미팅", true),
            ("납품", 10, 10, "최종 산출물 전달", row.isCollected),
            ("입금 완료", row.month, row.day, TSFormatMock.won(row.amount), row.isCollected)
        ]
        let stepJSON = steps.enumerated().map { index, step in
            "{\"id\":\(index + 1),\"title\":\"\(step.0)\",\"date\":\"\(dateText(year: year, month: step.1, day: step.2))\"," +
            "\"note\":\"\(step.3)\",\"isDone\":\(step.4)}"
        }.joined(separator: ",")
        let clientName = row.id == 1 ? "클라이언트 브릿지랩스" : "클라이언트 " + row.name.capitalized
        let amountNote = (row.isCollected ? "입금 확인" : "입금 예정") + " · 부가세 별도"
        return """
        {"code":200,"message":"조회 성공","data":{
          "contract":\(contractJSON(row, year: year)),
          "category":"외주",
          "clientName":"\(clientName)",
          "amountNote":"\(amountNote)",
          "steps":[\(stepJSON)],
          "pools":[{"kind":"OPERATION","ratio":40,"amount":\(row.amount * 4 / 10)},
                   {"kind":"RESERVE","ratio":30,"amount":\(row.amount * 3 / 10)},
                   {"kind":"DIVIDEND","ratio":30,"amount":\(row.amount * 3 / 10)}],
          "managerName":"이시우",
          "memberCount":5,
          "documentName":"\(row.name) 계약서.pdf"
        }}
        """
    }
}

/// Mock 문자열용 금액 표기 (Presentation 의 TSFormat 에 의존하지 않도록 분리)
private enum TSFormatMock {
    static func won(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: value)) ?? String(value)) + "원"
    }
}
