import Foundation

/// 가입 요청 Mock — 서버 `signup_request` 레코드 모양 (비밀번호는 응답에서 빠져요)
/// 검토 중 2건 · 승인 1건으로 시작하고, 01-2 에서 보낸 요청도 쌓여요.
final class MockSignupRequestStore: @unchecked Sendable {
    private struct Record {
        let id: Int
        let email: String
        let name: String
        let dept: String
        let major: String?
        let cohort: String?
        let message: String?
        let hasPassword: Bool
        let createdAt: Date
        var status = "PENDING"
        var approvedBy: String?
        var rejectionReason: String?
    }

    private let lock = NSLock()
    private var records: [Record]

    init(now: Date = Date()) {
        records = [
            Record(id: 3, email: "s26014@gsm.hs.kr", name: "유다인", dept: "Design", major: "UI/UX", cohort: "9기",
                   message: "디자인 시스템 작업에 함께하고 싶어요.", hasPassword: true, createdAt: now.addingTimeInterval(-3_600)),
            Record(id: 2, email: "s26021@gsm.hs.kr", name: "조현우", dept: "Dev", major: "iOS", cohort: nil,
                   message: nil, hasPassword: false, createdAt: now.addingTimeInterval(-86_400)),
            Record(id: 1, email: "s26003@gsm.hs.kr", name: "김하린", dept: "PMO", major: nil, cohort: "9기",
                   message: nil, hasPassword: true, createdAt: now.addingTimeInterval(-3 * 86_400), status: "APPROVED", approvedBy: "관리자")
        ]
    }

    /// POST /auth/signup-requests — 접수 번호를 돌려줘요.
    func create(_ request: AccountRequestRequestDTO) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let id = (records.map(\.id).max() ?? 0) + 1
        records.insert(Record(
            id: id, email: request.email, name: request.name, dept: request.dept, major: request.major,
            cohort: request.cohort, message: request.message, hasPassword: !request.password.isEmpty, createdAt: Date()
        ), at: 0)
        return id
    }

    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        let items = records.map { record -> [String: Any] in
            var fields: [String: Any] = [
                "id": String(record.id), "email": record.email, "name": record.name, "dept": record.dept,
                "status": record.status, "createdAt": MockBoardStore.pythonISO(record.createdAt)
            ]
            fields["major"] = record.major
            fields["cohort"] = record.cohort
            fields["message"] = record.message
            fields["approvedBy"] = record.approvedBy
            fields["rejectionReason"] = record.rejectionReason
            fields["rejectedBy"] = record.rejectionReason == nil ? nil : "관리자"
            return fields
        }
        return json(["items": items, "nextCursor": NSNull()])
    }

    enum ApproveResult {
        case approved(String)
        case notFound
        case duplicated
        case needsPassword
    }

    /// POST /admin/signup-requests/{id}/approve — 이미 승인된 이메일은 409, 비밀번호가 없는데 초기 비밀번호도 없으면 400
    func approve(id: Int, temporaryPassword: String?, memberId: String? = nil) -> ApproveResult {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.id == id }) else { return .notFound }
        guard records[index].status != "APPROVED" else { return .duplicated }
        guard records[index].hasPassword || !(temporaryPassword ?? "").isEmpty else { return .needsPassword }
        records[index].status = "APPROVED"
        records[index].approvedBy = "관리자"
        return .approved(json(["userId": String(100 + id), "memberId": memberId ?? NSNull(), "status": "APPROVED"]))
    }

    /// POST /admin/signup-requests/{id}/reject — 없으면 nil, 대기 중이 아니면 false
    func reject(id: Int, reason: String) -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.id == id }) else { return nil }
        guard records[index].status == "PENDING" else { return false }
        records[index].status = "REJECTED"
        records[index].rejectionReason = reason
        return true
    }

    private func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}
