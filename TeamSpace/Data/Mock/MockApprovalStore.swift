import Foundation

/// 결재 Mock 서버 저장소 — Figma 05-1 · 05-2 예시 내용
/// 목록 · 상세 · 승인 · 반려 · 의견 · 취소는 서버 develop `/approvals` 형식으로 내려줘요. (보는 사람 = 내 id 1)
/// 승인 · 반려 · 제출을 하면 상태가 메모리에 기억돼요.
final class MockApprovalStore: @unchecked Sendable {
    struct Item: Encodable {
        let id: Int
        let kind: String
        var title: String
        var amount: Int?
        var status: String
        let requesterName: String
        let requesterDepartment: String
        var summary: String?
        var updatedAt: String
        /// true: 내가 올린 결재 / false: 받은 결재
        let isMine: Bool
    }

    struct Comment: Encodable {
        let id: Int
        let authorName: String
        let body: String
        let createdAt: String
    }

    private let lock = NSLock()
    private var storage: [Item]
    private var comments: [Int: [Comment]] = [:]
    private var nextCommentId = 1_000
    private var nextDocumentId = 100
    /// 승인 · 반려 · 취소로 바뀐 결재선 (없으면 상태로 만들어요)
    private var lines: [Int: [Step]] = [:]
    private var rejectReasons: [Int: String] = [:]
    static let viewerId = 1
    /// 새로 작성한 문서의 상세 항목 · 사유
    private var drafts: [Int: (fields: [(String, String)], reason: String)] = [:]

    init(now: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        func ago(days: Double) -> String { formatter.string(from: now.addingTimeInterval(-days * 86_400)) }
        func mine(_ id: Int, _ title: String, _ amount: Int?, _ status: String, _ days: Double) -> Item {
            Item(id: id, kind: "EXPENSE", title: title, amount: amount, status: status, requesterName: "옥물결",
                 requesterDepartment: "Design", summary: nil, updatedAt: ago(days: days), isMine: true)
        }
        storage = [
            mine(1, "Book-on 테스트 기기 구매", 420_000, "IN_REVIEW", 0.02),
            mine(2, "11월 워크숍 장소 대관", nil, "DRAFT", 0.5),
            mine(3, "외부 강사 섭외비", 300_000, "REJECTED", 23),
            mine(4, "Figma 팀 플랜 갱신", 540_000, "APPROVED", 27),
            mine(5, "디자인 에셋 구독", 120_000, "APPROVED", 35),
            mine(6, "행사 현수막 제작", 85_000, "APPROVED", 40),
            mine(7, "MoSS 서버 비용", 66_000, "PENDING", 1.5),
            Item(id: 11, kind: "STAFFING", title: "Book-on 프로젝트 인력 지원", amount: nil, status: "PENDING",
                 requesterName: "이시우", requesterDepartment: "PMO", summary: "iOS 1명 · 8월~10월",
                 updatedAt: ago(days: 0.001), isMine: false),
            Item(id: 12, kind: "EXPENSE", title: "디자인 리뷰 외부 장소 대관", amount: 150_000, status: "PENDING",
                 requesterName: "오잉", requesterDepartment: "Design", summary: nil, updatedAt: ago(days: 1), isMine: false),
            Item(id: 13, kind: "EXPENSE", title: "BRIDGE 테스트 단말 대여", amount: 80_000, status: "APPROVED",
                 requesterName: "김민규", requesterDepartment: "Dev", summary: nil, updatedAt: ago(days: 4), isMine: false),
            Item(id: 14, kind: "EXPENSE", title: "중복 구독 결제 요청", amount: 29_000, status: "REJECTED",
                 requesterName: "이채율", requesterDepartment: "Dev", summary: nil, updatedAt: ago(days: 9), isMine: false)
        ]
        comments[1] = [Comment(id: 1, authorName: "이시우", body: "모델명만 견적서에 추가해 주세요!", createdAt: ago(days: 0.01))]
    }

    func items(mine: Bool) -> [Item] {
        lock.lock()
        defer { lock.unlock() }
        return storage.filter { $0.isMine == mine }
    }

    func item(id: Int) -> Item? {
        lock.lock()
        defer { lock.unlock() }
        return storage.first { $0.id == id }
    }

    /// 상태 바꾸기 (승인 · 반려 · 제출)
    @discardableResult
    func update(id: Int, status: String, now: Date = Date()) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return false }
        storage[index].status = status
        storage[index].updatedAt = ISO8601DateFormatter().string(from: now)
        lines[id] = nil
        return true
    }

    // MARK: 서버 develop /approvals 형식

    struct Step {
        let who: String
        let userId: Int
        let role: String
        var state: String
        var at: String
    }

    private static let kindNames = [
        "EXPENSE": "비용 승인", "STAFFING": "인력 지원", "PROJECT_REQUEST": "프로젝트 요청",
        "OPERATION_REQUEST": "운영 요청", "ETC": "기타 내부 문서"
    ]
    private static let statusNames = [
        "DRAFT": "작성 중", "PENDING": "결재 대기", "IN_REVIEW": "검토 중",
        "APPROVED": "승인", "REJECTED": "반려", "CANCELLED": "취소"
    ]

    /// 결재선 — 내가 올린 결재: 나(기안) → 안율(검토) → 김민준(승인) → 이시우(승인)
    ///          받은 결재: 요청자(기안) → 나(검토) → 김민준(승인) → 이시우(승인)
    private func line(for item: Item) -> [Step] {
        if let stored = lines[item.id] { return stored }
        let drafter = Step(who: item.requesterName, userId: item.isMine ? Self.viewerId : 30 + item.id, role: "기안",
                           state: "done", at: item.updatedAt)
        guard item.status != "DRAFT" else { return [drafter] }
        let first = item.isMine ? ("안율", 21) : ("홍길동", Self.viewerId)
        var steps = [
            Step(who: first.0, userId: first.1, role: "검토", state: "wait", at: "대기"),
            Step(who: "김민준", userId: 22, role: "승인", state: "wait", at: "대기"),
            Step(who: "이시우", userId: 23, role: "승인", state: "wait", at: "대기")
        ]
        switch item.status {
        case "APPROVED":
            for index in steps.indices { steps[index].state = "done"; steps[index].at = item.updatedAt }
        case "REJECTED":
            steps[0].state = "done"
            steps[0].at = item.updatedAt
        default:
            steps[0].state = "now"
            steps[0].at = "검토 중"
        }
        return [drafter] + steps
    }

    private func payload(for item: Item) -> [String: Any] {
        var fields: [String: String] = item.kind == "STAFFING"
            ? ["project": "Book-on", "type": "iOS 1명", "period": "2026.11 ~ 2026.12"]
            : ["type": "물품 구매", "project": "Book-on", "useDate": "2026.10.20"]
        var details: [String: Any] = [:]
        if let draft = drafts[item.id] {
            let keys = ["비용 유형": "type", "프로젝트": "project", "사용 예정일": "useDate", "투입 기간": "period"]
            fields = Dictionary(draft.fields.compactMap { title, value in keys[title].map { ($0, value) } }) { $1 }
            details["fields"] = draft.fields.map { ["title": $0.0, "value": $0.1] }
        }
        let steps = line(for: item)
        var result: [String: Any] = [
            "id": String(item.id),
            "kind": Self.kindNames[item.kind] ?? "기타 내부 문서",
            "title": item.title,
            "status": Self.statusNames[item.status] ?? item.status,
            "amount": item.amount.map { "\($0)원" } ?? "",
            "amountValue": item.amount ?? 0,
            "reason": reason(for: item),
            "author": item.requesterName,
            "authorId": String(item.isMine ? Self.viewerId : 30 + item.id),
            "date": item.updatedAt,
            "line": steps.map { ["who": $0.who, "userId": $0.userId, "role": $0.role, "state": $0.state, "at": $0.at] },
            "files": item.id == 1
                ? [["id": "9", "url": "/uploads/9", "filename": "견적서_iPhone.pdf", "size": 1_200_000, "contentType": "application/pdf"]]
                : [] as [[String: Any]],
            "comments": (comments[item.id] ?? []).map {
                ["id": String($0.id), "who": $0.authorName, "whoId": "", "meta": "", "text": $0.body, "createdAt": $0.createdAt]
            },
            "received": steps.contains { $0.userId == Self.viewerId && $0.role != "기안" && ($0.state == "now" || $0.state == "wait") }
        ]
        if item.kind == "STAFFING" { result["amount"] = fields["period"] ?? "" }
        if !details.isEmpty { result["details"] = details }
        if let reason = rejectReasons[item.id] { result["rejectReason"] = reason }
        for (key, value) in fields { result[key] = value }
        return result
    }

    /// GET /approvals?box= — mine: 내가 올린 것, received: 내 차례 · 다음 차례, handled: 내가 처리한 것(서버처럼 내 기안 포함)
    func serverListJSON(box: String, cursor: String?, limit: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        let matched = storage.filter { item in
            let steps = line(for: item)
            switch box {
            case "mine": return item.isMine
            case "received": return steps.contains { $0.userId == Self.viewerId && ($0.state == "now" || $0.state == "wait") }
            default: return steps.contains { $0.userId == Self.viewerId && $0.state == "done" }
            }
        }
        .filter { item in cursor.flatMap(Int.init).map { item.id < $0 } ?? true }
        .sorted { $0.id > $1.id }
        let page = Array(matched.prefix(limit))
        let next: Any = matched.count > limit ? page.last.map { String($0.id) } ?? NSNull() : NSNull()
        return Self.json(["items": page.map(payload), "nextCursor": next])
    }

    func serverDetailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let item = storage.first(where: { $0.id == id }) else { return nil }
        let steps = line(for: item)
        guard item.isMine || steps.contains(where: { $0.userId == Self.viewerId }) else { return nil }
        return Self.json(payload(for: item))
    }

    enum DecideError: Error { case notFound, notMyTurn, invalidState, missingReason }

    /// POST /approvals/{id}/approve · reject — 내 차례(now)인 단계만 처리해요.
    func decide(id: Int, approve: Bool, reason: String?, now: Date = Date()) -> Result<String, DecideError> {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return .failure(.notFound) }
        guard ["PENDING", "IN_REVIEW"].contains(storage[index].status) else { return .failure(.invalidState) }
        var steps = line(for: storage[index])
        guard let mine = steps.firstIndex(where: { $0.userId == Self.viewerId && $0.state == "now" }) else {
            return .failure(.notMyTurn)
        }
        let stamp = ISO8601DateFormatter().string(from: now)
        steps[mine].state = "done"
        steps[mine].at = stamp
        if approve {
            if let next = steps.firstIndex(where: { $0.state == "wait" }) {
                steps[next].state = "now"
                steps[next].at = "검토 중"
                storage[index].status = "IN_REVIEW"
            } else {
                storage[index].status = "APPROVED"
            }
        } else {
            guard let reason, !reason.trimmingCharacters(in: .whitespaces).isEmpty else { return .failure(.missingReason) }
            storage[index].status = "REJECTED"
            rejectReasons[id] = reason
        }
        storage[index].updatedAt = stamp
        lines[id] = steps
        return .success(Self.json(["id": String(id), "status": Self.statusNames[storage[index].status] ?? ""]))
    }

    /// POST /approvals/{id}/cancel — 내가 올린 작성 중 · 대기 · 검토 중 결재만
    func cancel(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id && $0.isMine }),
              ["DRAFT", "PENDING", "IN_REVIEW"].contains(storage[index].status) else { return nil }
        lines[id] = line(for: storage[index])
        storage[index].status = "CANCELLED"
        return Self.json(["id": String(id), "status": "취소"])
    }

    /// POST /approvals/{id}/comments — `{id, who, whoId, meta, text, createdAt}`
    func serverComment(id: Int, text: String, now: Date = Date()) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard storage.contains(where: { $0.id == id }) else { return nil }
        nextCommentId += 1
        let comment = Comment(id: nextCommentId, authorName: "홍길동", body: text, createdAt: ISO8601DateFormatter().string(from: now))
        comments[id, default: []].append(comment)
        return Self.json([
            "id": String(comment.id), "who": comment.authorName, "whoId": String(Self.viewerId),
            "meta": "NativeOps", "text": text, "createdAt": comment.createdAt
        ])
    }

    private func reason(for item: Item) -> String {
        if let draft = drafts[item.id] { return draft.reason }
        switch item.id {
        case 1: return "iOS 실기기 테스트용 iPhone 1대가 필요해요. 기존 기기는 OS 지원이 끝났어요."
        case 11: return "출시 전 QA와 위젯 기능 개발이 겹쳐서 iOS 인원이 1명 더 필요해요."
        default: return "\(item.title) 진행을 위해 요청해요."
        }
    }

    private struct Envelope<T: Encodable>: Encodable {
        let code: Int
        let message: String
        let data: T
    }

    /// 아직 옛 형식인 /documents · /workspace/documents 응답
    private func encode<T: Encodable>(_ data: T, message: String = "조회 성공") -> String {
        let encoded = (try? JSONEncoder().encode(Envelope(code: 200, message: message, data: data))) ?? Data()
        return String(decoding: encoded, as: UTF8.self)
    }

    private static func json(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: 05-5 · 05-6 작성 · 제출

    /// POST /documents — 내가 올린 결재에 '작성 중' 으로 추가
    func createJSON(
        kind: String,
        title: String,
        amount: Int?,
        fields: [(String, String)],
        reason: String,
        now: Date = Date()
    ) -> String {
        lock.lock()
        nextDocumentId += 1
        let id = nextDocumentId
        storage.append(Item(
            id: id, kind: kind, title: title, amount: amount, status: "DRAFT", requesterName: "홍길동",
            requesterDepartment: "NativeOps", summary: nil, updatedAt: ISO8601DateFormatter().string(from: now), isMine: true
        ))
        drafts[id] = (fields, reason)
        lock.unlock()
        struct Created: Encodable { let documentId: Int }
        return encode(Created(documentId: id), message: "작성 완료")
    }

    // MARK: 07-4 · 07-5 내 문서

    private struct MyDocumentItem: Encodable {
        let id: Int
        let kind: String
        let title: String
        let amount: Int?
        let status: String
        let projectName: String?
        let summary: String?
        let submittedAt: String?
        let updatedAt: String
        let currentApproverName: String?
        let currentApproverDepartment: String?
        let currentStepTitle: String?
        let decidedByName: String?
        let decidedByDepartment: String?
        let decidedAt: String?
        let rejectReason: String?
    }

    /// GET /workspace/documents — 내가 올린 결재를 07-4 모양으로. 결재선은 상세(approvers)와 같아요.
    func myDocumentsJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        let list = storage.filter(\.isMine).map { item -> MyDocumentItem in
            let isWaiting = item.status == "PENDING" || item.status == "IN_REVIEW"
            let isDecided = item.status == "APPROVED" || item.status == "REJECTED"
            let decider: (String, String)? = item.status == "APPROVED" ? ("이시우", "Leader")
                : item.status == "REJECTED" ? ("안율", "OL") : nil
            return MyDocumentItem(
                id: item.id,
                kind: item.kind,
                title: item.title,
                amount: item.amount,
                status: item.status,
                projectName: item.id == 1 || item.kind == "STAFFING" ? "Book-on" : "NativeLab",
                summary: item.status == "DRAFT" ? (drafts[item.id]?.reason ?? item.summary ?? "작성하던 내용이 저장돼 있어요.") : nil,
                submittedAt: item.status == "DRAFT" ? nil : item.updatedAt,
                updatedAt: item.updatedAt,
                currentApproverName: isWaiting ? "안율" : nil,
                currentApproverDepartment: isWaiting ? "OL" : nil,
                currentStepTitle: item.status == "PENDING" ? "1차 검토 대기" : item.status == "IN_REVIEW" ? "1차 검토 중" : nil,
                decidedByName: decider?.0,
                decidedByDepartment: decider?.1,
                decidedAt: isDecided ? item.updatedAt : nil,
                rejectReason: item.status == "REJECTED" ? "사용 기간과 인원별 산출 근거를 보완해 주세요." : nil
            )
        }
        return encode(["list": list])
    }

    /// DELETE /documents/{id} — 내가 작성 중인 문서만 지워요.
    func deleteDraft(id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id && $0.isMine && $0.status == "DRAFT" }) else {
            return false
        }
        storage.remove(at: index)
        drafts[id] = nil
        return true
    }
}
