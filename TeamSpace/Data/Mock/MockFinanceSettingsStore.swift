import Foundation

/// 재무 요약 설정 Mock — GET · PATCH /admin/finance/settings. 저장한 풀은 GET /finance/summary 에도 보여요.
final class MockFinanceSettingsStore: @unchecked Sendable {
    private let lock = NSLock()
    private var settings: [String: Any] = [
        "pools": MockFinanceFixture.pools,
        "flow": [] as [Any],
        "notices": [] as [Any]
    ]

    var pools: [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return settings["pools"] as? [[String: Any]] ?? []
    }

    func json() -> String {
        lock.lock()
        defer { lock.unlock() }
        return Self.json(settings)
    }

    /// 서버처럼 보낸 키만 덮어써요. 풀 금액이 음수면 422
    func patch(_ body: [String: Any]) -> (status: Int, json: String) {
        if let pools = body["pools"] as? [[String: Any]], pools.contains(where: { ($0["amount"] as? Int ?? 0) < 0 }) {
            return (422, #"{"detail":"풀 금액은 0 이상이어야 합니다."}"#)
        }
        lock.lock()
        defer { lock.unlock() }
        settings.merge(body) { _, new in new }
        return (200, Self.json(settings))
    }

    private static func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
