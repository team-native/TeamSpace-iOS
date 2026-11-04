import Foundation

/// 계약 정보 Mock — GET /finance/contracts/{project} · POST /admin/finance/contracts · PATCH /admin/finance/contracts/{project}
/// 처음엔 예시 계약(iOS 앱 프로토타입)만 있어요.
final class MockContractStore: @unchecked Sendable {
    private let lock = NSLock()
    private var contracts: [String: [String: Any]] = [:]

    init() {
        if let json = MockFinanceFixture.contract(project: "iOS 앱 프로토타입"),
           let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] {
            contracts["iOS 앱 프로토타입"] = object
        }
    }

    func detailJSON(project: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return contracts[project].map(Self.json)
    }

    /// 서버처럼 project 가 없으면 400, 이미 있으면 409
    func create(_ body: [String: Any]) -> (status: Int, json: String) {
        guard let project = (body["project"] ?? body["projectId"]) as? String, !project.isEmpty else {
            return (400, #"{"detail":"프로젝트 식별 정보가 필요합니다."}"#)
        }
        if let error = Self.negativeMoney(body) { return error }
        lock.lock()
        defer { lock.unlock() }
        guard contracts[project] == nil else {
            return (409, #"{"detail":"해당 프로젝트의 계약 정보가 이미 등록되어 있습니다."}"#)
        }
        contracts[project] = body
        return (201, Self.json(body))
    }

    func update(project: String, _ body: [String: Any]) -> (status: Int, json: String) {
        if let error = Self.negativeMoney(body) { return error }
        lock.lock()
        defer { lock.unlock() }
        guard let current = contracts[project] else { return (404, #"{"detail":"계약 정보를 찾을 수 없습니다."}"#) }
        let updated = current.merging(body) { _, new in new }
        contracts[project] = updated
        return (200, Self.json(updated))
    }

    private static func negativeMoney(_ body: [String: Any]) -> (status: Int, json: String)? {
        for key in ["total", "collected"] {
            if let value = body[key] as? Int, value < 0 { return (422, #"{"detail":"계약 금액은 0 이상이어야 합니다."}"#) }
        }
        return nil
    }

    private static func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
