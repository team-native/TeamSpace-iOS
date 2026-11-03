import Foundation

/// 재정 권한 Mock — 서버처럼 Admin · FA · Leader 가 있으면 열람 가능, 주면 FA 추가 · 회수하면 FA 만 빼요.
final class MockFinancePermissionStore: @unchecked Sendable {
    private struct Person {
        let id: Int
        let name: String
        let email: String
        var roles: [String]
    }

    private let lock = NSLock()
    private var people: [Person] = [
        Person(id: 1, name: "홍길동", email: "s00000@gsm.hs.kr", roles: ["Member", "PM"]),
        Person(id: 2, name: "김민준", email: "s26001@gsm.hs.kr", roles: ["Leader"]),
        Person(id: 3, name: "관리자", email: "admin@gsm.hs.kr", roles: ["Admin"]),
        Person(id: 4, name: "옥물결", email: "s26011@gsm.hs.kr", roles: ["Member"]),
        Person(id: 5, name: "이시우", email: "s26007@gsm.hs.kr", roles: ["FA", "PM"]),
        Person(id: 6, name: "양지우", email: "s26009@gsm.hs.kr", roles: ["Member"])
    ]

    private static func canView(_ roles: [String]) -> Bool {
        !Set(roles).isDisjoint(with: ["Admin", "FA", "Leader"])
    }

    private func fields(_ person: Person) -> [String: Any] {
        ["id": String(person.id), "name": person.name, "email": person.email, "roles": person.roles, "canViewFinance": Self.canView(person.roles)]
    }

    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return json(["items": people.map(fields), "nextCursor": NSNull()])
    }

    /// 없는 사용자면 nil
    func update(id: Int, canViewFinance: Bool) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = people.firstIndex(where: { $0.id == id }) else { return nil }
        var roles = Set(people[index].roles)
        if canViewFinance {
            if !Self.canView(Array(roles)) { roles.insert("FA") }
        } else {
            roles.remove("FA")
        }
        people[index].roles = roles.sorted()
        let person = people[index]
        return json(["id": String(person.id), "roles": person.roles, "canViewFinance": Self.canView(person.roles)])
    }

    private func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}
