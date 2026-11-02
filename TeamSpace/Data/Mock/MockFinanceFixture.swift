import Foundation

/// Mock 재무 — 서버 `/finance/summary` · `/finance/receipts` · `/finance/contracts/{project}` 형식 (Figma 04 예시 숫자)
/// 서버처럼 재정 권한(FA 토큰)이 없으면 403 이에요.
enum MockFinanceFixture {
    static let forbidden = #"{"detail":"재정 정보 열람 권한이 없습니다."}"#

    struct Receipt {
        let id: Int
        let client: String
        let project: String
        let amount: Int
        let month: Int
        let day: Int
        let isCollected: Bool
    }

    /// Figma 04-3 수금 내역 (올해 8 ~ 10월)
    static let receipts: [Receipt] = [
        Receipt(id: 7, client: "CAMPUS", project: "관리자 도구 개발", amount: 2_500_000, month: 10, day: 29, isCollected: false),
        Receipt(id: 1, client: "BRIDGE", project: "iOS 앱 프로토타입", amount: 3_600_000, month: 10, day: 18, isCollected: true),
        Receipt(id: 2, client: "MOTION", project: "브랜드 웹 구축", amount: 2_800_000, month: 10, day: 12, isCollected: true),
        Receipt(id: 4, client: "ORBIT", project: "사내 대시보드", amount: 4_200_000, month: 9, day: 27, isCollected: true),
        Receipt(id: 5, client: "PLANT", project: "커머스 리뉴얼", amount: 3_100_000, month: 9, day: 14, isCollected: true),
        Receipt(id: 6, client: "HELLO", project: "온보딩 앱 MVP", amount: 5_000_000, month: 8, day: 30, isCollected: true),
        Receipt(id: 3, client: "NOTE", project: "노트 앱 디자인", amount: 1_800_000, month: 8, day: 11, isCollected: true)
    ]

    /// 04-5 막대 높이 비율 (마지막 달 = 7,260,000 / 3,480,000)
    private static let incomeHeights = [40, 52, 48, 66, 72, 80, 96]
    private static let expenseHeights = [26, 30, 34, 38, 40, 46, 50]

    /// GET /finance/summary — 이번 달까지 7개월 흐름
    /// `month` 가 "YYYY-MM" 이면 그 달 수입 · 지출, 재정 권한이 없으면 수금 내역 · 공지 · 풀 메모를 빼요. (서버 develop)
    static func summary(now: Date = Date(), month selected: String? = nil, isFA: Bool = true, calendar: Calendar = .current) -> String {
        let end = calendar.startOfMonth(for: now)
        let flow: [[String: Any]] = (0..<7).compactMap { index in
            guard let month = calendar.date(byAdding: .month, value: index - 6, to: end) else { return nil }
            let parts = calendar.dateComponents([.year, .month], from: month)
            return [
                "month": String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0),
                "income": 7_260_000 * incomeHeights[index] / 96 / 10_000 * 10_000,
                "expense": 3_480_000 * expenseHeights[index] / 50 / 10_000 * 10_000
            ]
        }
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let current = String(format: "%04d-%02d", year, month)
        let target = selected ?? current
        let row = flow.first { $0["month"] as? String == target }
        let revenue = target == current ? 7_260_000 : (row?["income"] as? Int ?? 0)
        let expense = target == current ? 3_480_000 : (row?["expense"] as? Int ?? 0)
        var result: [String: Any] = [
            "period": "\(target.prefix(4))년 \(target.suffix(2))월",
            "month": target,
            "demo": false,
            "lastSyncedAt": ISO8601DateFormatter().string(from: now),
            "summary": [
                "available": 3_560_000, "monthlyRevenue": revenue, "monthlyExpense": expense,
                "externalReceipts": receipts.reduce(0) { $0 + $1.amount }, "reserveBalance": 2_670_000
            ],
            "pools": [
                ["id": "operation", "label": "운영풀", "amount": 3_560_000, "ratio": 40, "color": "#3182f6", "note": "운영 자금"],
                ["id": "reserve", "label": "적립풀", "amount": 2_670_000, "ratio": 30, "color": "#7c5cff", "note": "예비 자금"],
                ["id": "dividend", "label": "배당풀", "amount": 2_670_000, "ratio": 30, "color": "#ff8a3d", "note": "참여자 배당"]
            ],
            "flow": flow
        ]
        if isFA {
            result["receipts"] = receipts.map { receiptJSON($0, year: year, withId: false) }
            result["notices"] = [] as [Any]
            result["member"] = ["email": "fa@gsm.hs.kr", "name": "김민준"]
        } else {
            result["pools"] = (result["pools"] as? [[String: Any]] ?? []).map { $0.filter { $0.key != "note" } }
        }
        return json(result)
    }

    /// GET /finance/receipts?from&to&cursor&limit — 최근 날짜 순, totals 는 기간 전체
    static func receipts(query: [String: String], now: Date = Date(), calendar: Calendar = .current) -> String {
        let year = query["from"].flatMap { Int($0.prefix(4)) } ?? calendar.component(.year, from: now)
        let offset = query["cursor"].flatMap(Int.init) ?? 0
        let limit = query["limit"].flatMap(Int.init) ?? 20
        let page = Array(receipts.dropFirst(offset).prefix(limit))
        let paid = receipts.filter(\.isCollected).reduce(0) { $0 + $1.amount }
        let total = receipts.reduce(0) { $0 + $1.amount }
        return json([
            "items": page.map { receiptJSON($0, year: year, withId: true) },
            "nextCursor": offset + limit < receipts.count ? String(offset + limit) as Any : NSNull(),
            "totals": ["totalOrder": total, "paid": paid, "pending": total - paid, "overdue": 0]
        ])
    }

    /// GET /finance/contracts/{project} — 프런트 `CONTRACTS[project]` 형식. iOS 앱 프로토타입만 등록돼 있어요.
    static func contract(project: String, now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard project == "iOS 앱 프로토타입" else { return nil }
        let year = calendar.component(.year, from: now)
        return json([
            "project": project, "projectId": "1", "pm": "이시우 · PM", "signed": "\(year).09.02",
            "total": 3_600_000, "collected": 3_600_000, "step": 6,
            "stepDates": ["08.20", "08.27", "09.02 계약서 서명", "09.05 킥오프", "10.10 최종 산출물 전달", "10.18"],
            "staff": "iOS 2 · Design 1 · Backend 1 · PM 1", "split": "운영 60% · 적립 30% · 배당 10%",
            "file": "BRIDGE 계약서.pdf"
        ])
    }

    private static func receiptJSON(_ row: Receipt, year: Int, withId: Bool) -> [String: Any] {
        var item: [String: Any] = [
            "client": row.client, "project": row.project, "amount": row.amount,
            "status": row.isCollected ? "입금 완료" : "입금 대기",
            "date": String(format: "%04d-%02d-%02d", year, row.month, row.day)
        ]
        if withId { item["id"] = String(row.id) }
        return item
    }

    private static func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
