import Foundation

/// 수금 등록 · 수정 Mock — POST /admin/finance/receipts · PATCH /admin/finance/receipts/{id}
/// 예시 수금(MockFinanceFixture)에 고친 값을 덮고, 새로 등록한 수금을 더해 GET /finance/receipts 로 돌려줘요.
final class MockReceiptStore: @unchecked Sendable {
    static let requiredKeys = ["client", "project", "amount", "status", "date"]

    private let lock = NSLock()
    private var added: [[String: Any]] = []
    private var patches: [String: [String: Any]] = [:]
    private var nextId = 1000

    /// 예시 수금 목록에 고친 값 · 새 수금을 반영해요.
    func merge(_ items: [[String: Any]]) -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        let patched = items.map { item -> [String: Any] in
            guard let id = item["id"] as? String, let patch = patches[id] else { return item }
            return item.merging(patch) { _, new in new }
        }
        let extra = added.map { item -> [String: Any] in
            guard let id = item["id"] as? String, let patch = patches[id] else { return item }
            return item.merging(patch) { _, new in new }
        }
        return (patched + extra).sorted { ($0["date"] as? String ?? "") > ($1["date"] as? String ?? "") }
    }

    func create(_ body: [String: Any]) -> (status: Int, json: String) {
        for key in Self.requiredKeys where body[key] == nil {
            return (400, #"{"detail":"\#(key) 항목은 필수입니다."}"#)
        }
        guard let amount = body["amount"] as? Int, amount >= 0 else {
            return (422, #"{"detail":"수금 금액은 0 이상이어야 합니다."}"#)
        }
        lock.lock()
        defer { lock.unlock() }
        nextId += 1
        var item = body
        item["id"] = String(nextId)
        item["amount"] = amount
        added.append(item)
        return (201, Self.json(item))
    }

    func update(id: String, _ body: [String: Any], exists: Bool) -> (status: Int, json: String) {
        lock.lock()
        defer { lock.unlock() }
        guard exists || added.contains(where: { $0["id"] as? String == id }) else {
            return (404, #"{"detail":"요청한 항목을 찾을 수 없습니다."}"#)
        }
        if let amount = body["amount"], (amount as? Int ?? -1) < 0 {
            return (422, #"{"detail":"수금 금액은 0 이상이어야 합니다."}"#)
        }
        patches[id, default: [:]].merge(body) { _, new in new }
        return (200, Self.json(["id": id].merging(patches[id] ?? [:]) { old, _ in old }))
    }

    private static func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
