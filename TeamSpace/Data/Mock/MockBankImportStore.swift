import Foundation

/// 은행 거래 Mock — 서버 `finance.py` 처럼 확인 · 제외 · 반영 상태를 바꿔요.
/// 입금은 연결된 수주 계약이 있어야 확인돼요. 반영하면 "이미 반영됨" 이 되고 다시 바꿀 수 없어요.
final class MockBankImportStore: @unchecked Sendable {
    private struct Row {
        let id: String
        let hoursAgo: Int
        let counterparty: String
        let amount: Int
        let direction: String
        var matchedProject: String?
        var status: String
        var confirmed = false
        var committedAt: Date?
    }

    private let lock = NSLock()
    private let now: Date
    private var rows: [Row] = [
        Row(id: "105", hoursAgo: 3, counterparty: "(주)그린랩", amount: 3_000_000, direction: "입금", matchedProject: "Green Note · (주)그린랩", status: "자동 매칭"),
        Row(id: "104", hoursAgo: 20, counterparty: "노션코리아", amount: 54_000, direction: "출금", status: "확인 필요"),
        Row(id: "103", hoursAgo: 30, counterparty: "김OO", amount: 120_000, direction: "입금", status: "확인 필요"),
        Row(id: "102", hoursAgo: 50, counterparty: "피그마", amount: 33_000, direction: "출금", status: "제외"),
        Row(id: "101", hoursAgo: 80, counterparty: "북온", amount: 1_500_000, direction: "입금", matchedProject: "Book-on · 북온", status: "이미 반영됨",
            committedAt: Date(timeIntervalSinceNow: -70 * 3600))
    ]

    private var lastSyncedAt: Date?
    private var syncFailures = 0
    /// 테스트에서 불러오기 실패를 흉내 내요.
    var failsSync = false

    init(now: Date = Date()) {
        self.now = now
    }

    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        let items: [[String: Any]] = rows.map { row in
            [
                "rowId": row.id,
                "date": iso(now.addingTimeInterval(-Double(row.hoursAgo) * 3600)),
                "counterparty": row.counterparty,
                "amount": row.amount,
                "direction": row.direction,
                "matchedProject": row.matchedProject ?? NSNull(),
                "status": row.status,
                "confirmed": row.confirmed,
                "balanceAfter": NSNull(),
                "committedAt": row.committedAt.map(iso) ?? NSNull(),
                "committedBy": row.committedAt == nil ? NSNull() : "양지우"
            ]
        }
        return json(["items": items, "nextCursor": NSNull()])
    }

    /// PATCH /finance/bank-imports/{rowId}
    func review(id: String, confirm: Bool, exclude: Bool, matchedProject: String? = nil) -> (status: Int, json: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let index = rows.firstIndex(where: { $0.id == id }) else {
            return (404, #"{"detail":"은행 거래를 찾을 수 없습니다."}"#)
        }
        guard rows[index].status != "이미 반영됨" else { return (409, #"{"detail":"이미 재정에 반영된 거래입니다."}"#) }
        if exclude {
            rows[index].status = "제외"
            rows[index].confirmed = false
            return (200, json(["rowId": id, "status": "제외"]))
        }
        if rows[index].direction == "입금" {
            if let matchedProject, !matchedProject.isEmpty {
                // 서버처럼 계약의 project 이름으로 찾아요.
                guard MockFinanceFixture.receipts.contains(where: { $0.project == matchedProject }) else {
                    return (404, #"{"detail":"연결할 수주 계약을 찾을 수 없습니다."}"#)
                }
                rows[index].matchedProject = matchedProject
            }
            guard rows[index].matchedProject != nil else { return (404, #"{"detail":"연결할 수주 계약을 찾을 수 없습니다."}"#) }
            rows[index].status = confirm ? "확인 완료" : "자동 매칭"
        } else {
            if matchedProject?.isEmpty == false { return (422, #"{"detail":"출금 거래는 수주 계약에 연결할 수 없습니다."}"#) }
            rows[index].status = confirm ? "확인 완료" : "확인 필요"
        }
        rows[index].confirmed = confirm
        let row = rows[index]
        return (200, json(["rowId": id, "matchedProject": row.matchedProject ?? NSNull(), "confirmed": row.confirmed, "status": row.status]))
    }

    /// GET /finance/bank-accounts — 서버처럼 아직 은행 연동 업체는 정해지지 않았어요(provider_pending).
    func accountJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return json([
            "connected": false, "configured": true, "connectionStatus": "provider_pending",
            "provider": "mock", "accountNumber": "******1234", "alias": "NativeOps 운영 계좌",
            "lastSyncedAt": lastSyncedAt.map { iso($0) as Any } ?? NSNull(),
            "thisMonth": [
                "inboundCount": rows.filter { $0.direction == "입금" }.count,
                "outboundCount": rows.filter { $0.direction == "출금" }.count
            ],
            "consecutiveFailures": syncFailures, "recentFailures": []
        ])
    }

    /// POST /finance/bank-syncs — 처음엔 새 입금 1건, 그다음엔 새 거래 없음.
    /// `failsSync` 면 서버처럼 503 `{detail: {message, lastSuccessfulSyncAt}}`
    func sync() -> (status: Int, json: String) {
        lock.lock()
        defer { lock.unlock() }
        if failsSync {
            syncFailures += 1
            return (503, json(["detail": ["message": "은행 연동 업체가 아직 정해지지 않았습니다.", "lastSuccessfulSyncAt": lastSyncedAt.map { iso($0) as Any } ?? NSNull()]]))
        }
        var imported = 0
        if !rows.contains(where: { $0.id == "106" }) {
            rows.insert(Row(id: "106", hoursAgo: 0, counterparty: "모션스튜디오", amount: 1_400_000, direction: "입금", status: "확인 필요"), at: 0)
            imported = 1
        }
        let at = Date()
        lastSyncedAt = at
        syncFailures = 0
        return (200, json(["success": true, "fetchedCount": imported, "importedCount": imported, "lastSyncedAt": iso(at)]))
    }

    /// POST /finance/bank-import-commits
    func commit(rowIds: [String]) -> (status: Int, json: String) {
        lock.lock()
        defer { lock.unlock() }
        let targets = rows.indices.filter { rowIds.contains(rows[$0].id) && rows[$0].confirmed && rows[$0].status == "확인 완료" }
        guard targets.count == Set(rowIds).count else {
            return (409, #"{"detail":"선택한 거래 중 확인되지 않았거나 이미 반영된 항목이 있습니다."}"#)
        }
        let committedAt = Date()
        var receipts = 0
        var expenses = 0
        for index in targets {
            if rows[index].direction == "입금" { receipts += 1 } else { expenses += 1 }
            rows[index].status = "이미 반영됨"
            rows[index].confirmed = false
            rows[index].committedAt = committedAt
        }
        return (200, json([
            "committedCount": targets.count, "receiptCount": receipts, "expenseCount": expenses,
            "committedAt": iso(committedAt), "rowIds": targets.map { rows[$0].id }
        ]))
    }

    private func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }

    private func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
