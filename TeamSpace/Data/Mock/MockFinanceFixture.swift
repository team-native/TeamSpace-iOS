import Foundation

/// 재무 API 가짜 응답 — Figma 04 재무 예시 내용
/// 고른 달마다 숫자가 조금씩 달라지게 만들어 기간 선택(04-4)을 확인할 수 있게 합니다.
enum MockFinanceFixture {
    /// 달마다 다른 배수 (10월 = 1.0 → Figma 숫자 그대로)
    static func scale(for month: Date, calendar: Calendar = .current) -> Double {
        let value = calendar.component(.month, from: month)
        return 1.0 - Double((10 - value + 12) % 12) * 0.06
    }

    /// GET /finance/projects — Figma 04-9 예시. FA 토큰이 아니면 금액을 null 로 가립니다. (04-8)
    static func projects(yearText: String?, isFA: Bool, now: Date = Date()) -> String {
        let year = yearText.flatMap(Int.init) ?? Calendar.current.component(.year, from: now)
        let rows: [(String, String, Int, Int)] = [
            ("예약 서비스 앱 UI 제작", "IN_PROGRESS", 4_200_000, 2_100_000),
            ("학과 행사 웹페이지", "IN_PROGRESS", 1_600_000, 800_000),
            ("모바일 앱 유지보수", "IN_PROGRESS", 5_400_000, 2_700_000),
            ("브랜드 소개 랜딩페이지", "COMPLETED", 8_720_000, 8_720_000),
            ("동아리 행사 굿즈 디자인", "COMPLETED", 2_000_000, 2_000_000),
            ("교내 설문 웹앱", "COMPLETED", 1_500_000, 1_500_000),
            ("스타트업 IR 자료 디자인", "COMPLETED", 1_800_000, 1_800_000),
            ("카페 주문 키오스크 UI", "IN_PROGRESS", 1_680_000, 240_000),
            ("지역 축제 안내 페이지", "IN_PROGRESS", 1_500_000, 0)
        ]
        func amount(_ value: Int) -> String { isFA ? String(value) : "null" }
        let list = rows.enumerated().map { index, row in
            #"{"id":\#(index + 1),"name":"\#(row.0)","status":"\#(row.1)","contractAmount":\#(amount(row.2)),"paidAmount":\#(amount(row.3))}"#
        }.joined(separator: ",")
        let total = rows.reduce(0) { $0 + $1.2 }
        let paid = rows.reduce(0) { $0 + $1.3 }
        return """
        {"code":200,"message":"조회 성공","data":{"year":\(year),"yearCount":\(rows.count),\
        "totalContractAmount":\(amount(total)),"totalPaidAmount":\(amount(paid)),\
        "monthNewContracts":2,"monthDeposits":3,"list":[\(list)]}}
        """
    }

    /// GET /finance/flows — Figma 04-5 막대 높이 비율 그대로 (마지막 달 = 7,260,000 / 3,480,000)
    static func flows(toText: String?, countText: String?, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let end = calendar.startOfMonth(for: toText.flatMap(FinanceMonthParameter.date(from:)) ?? now)
        let incomeHeights = [40, 52, 48, 66, 72, 80, 96]
        let expenseHeights = [26, 30, 34, 38, 40, 46, 50]
        let count = min(max(countText.flatMap(Int.init) ?? 7, 1), incomeHeights.count)
        let formatter = ISO8601DateFormatter()
        let items = (0..<count).compactMap { index -> String? in
            let offset = index - (count - 1)
            guard let month = calendar.date(byAdding: .month, value: offset, to: end) else { return nil }
            let heightIndex = incomeHeights.count - count + index
            let income = 7_260_000 * incomeHeights[heightIndex] / 96 / 10_000 * 10_000
            let expense = 3_480_000 * expenseHeights[heightIndex] / 50 / 10_000 * 10_000
            return #"{"month":"\#(formatter.string(from: month))","income":\#(income),"expense":\#(expense)}"#
        }
        return #"{"code":200,"message":"조회 성공","data":{"list":[\#(items.joined(separator: ","))]}}"#
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
