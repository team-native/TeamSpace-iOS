import Foundation

/// 결재 Mock 서버 저장소 — Figma 05-1 · 05-2 예시 내용
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
        return true
    }

    func listJSON(mine: Bool) -> String {
        struct Envelope: Encodable {
            let code: Int
            let message: String
            let data: [String: [Item]]
        }
        let envelope = Envelope(code: 200, message: "조회 성공", data: ["list": items(mine: mine)])
        let data = (try? JSONEncoder().encode(envelope)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: 05-3 · 05-4 상세 · 결재

    private struct Field: Encodable {
        let title: String
        let value: String
    }

    private struct ApproverItem: Encodable {
        let approvalId: Int
        let name: String
        let role: String
        let status: String
        let note: String
    }

    private struct Attachment: Encodable {
        let name: String
        let sizeText: String
    }

    private struct Detail: Encodable {
        let document: Item
        let fields: [Field]
        let reason: String
        let approvers: [ApproverItem]
        let attachments: [Attachment]
        let comments: [Comment]
        let isMine: Bool
        let myApprovalId: Int?
    }

    private struct Envelope<T: Encodable>: Encodable {
        let code: Int
        let message: String
        let data: T
    }

    private func encode<T: Encodable>(_ data: T, message: String = "조회 성공") -> String {
        let encoded = (try? JSONEncoder().encode(Envelope(code: 200, message: message, data: data))) ?? Data()
        return String(decoding: encoded, as: UTF8.self)
    }

    /// 결재선 — 내가 올린 결재: 안율(OL) → 김민준(FA) → 이시우(Leader)
    ///          받은 결재: 나(OL) → 김민준(FA) → 이시우(Leader)
    private func approvers(for item: Item) -> [ApproverItem] {
        let first = item.isMine ? ("안율", "OL") : ("홍길동", "OL")
        let firstStatus: String
        switch item.status {
        case "APPROVED": firstStatus = "APPROVED"
        case "REJECTED": firstStatus = "REJECTED"
        case "PENDING", "IN_REVIEW": firstStatus = "REVIEWING"
        default: firstStatus = "WAITING"
        }
        return [
            ApproverItem(approvalId: item.id * 10 + 1, name: first.0, role: first.1, status: firstStatus,
                         note: firstStatus == "REVIEWING" ? "오늘 10:12 확인" : "처리 완료"),
            ApproverItem(approvalId: item.id * 10 + 2, name: "김민준", role: "FA", status: "WAITING", note: "이전 단계 승인 후"),
            ApproverItem(approvalId: item.id * 10 + 3, name: "이시우", role: "Leader", status: "WAITING", note: "이전 단계 승인 후")
        ]
    }

    private func fields(for item: Item) -> [Field] {
        if item.kind == "STAFFING" {
            return [
                Field(title: "프로젝트", value: "Book-on"),
                Field(title: "필요 직군", value: "iOS"),
                Field(title: "인원", value: "1명"),
                Field(title: "투입 기간", value: "2026.11 ~ 2026.12")
            ]
        }
        return [
            Field(title: "비용 유형", value: "물품 구매"),
            Field(title: "프로젝트", value: "Book-on"),
            Field(title: "사용 예정일", value: "2026.10.20")
        ]
    }

    private func reason(for item: Item) -> String {
        switch item.id {
        case 1: return "iOS 실기기 테스트용 iPhone 1대가 필요해요. 기존 기기는 OS 지원이 끝났어요."
        case 11: return "출시 전 QA와 위젯 기능 개발이 겹쳐서 iOS 인원이 1명 더 필요해요."
        default: return "\(item.title) 진행을 위해 요청해요."
        }
    }

    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let item = storage.first(where: { $0.id == id }) else { return nil }
        let isWaiting = item.status == "PENDING" || item.status == "IN_REVIEW"
        let detail = Detail(
            document: item,
            fields: fields(for: item),
            reason: reason(for: item),
            approvers: approvers(for: item),
            attachments: item.id == 1 ? [Attachment(name: "견적서_iPhone.pdf", sizeText: "1.2MB")] : [],
            comments: comments[id] ?? [],
            isMine: item.isMine,
            myApprovalId: !item.isMine && isWaiting ? item.id * 10 + 1 : nil
        )
        return encode(detail)
    }

    /// POST /approvals/{approvalId}/decide — 결재 단계 ID 의 앞자리가 문서 ID
    func decideJSON(approvalId: Int, decision: String, comment: String?, now: Date = Date()) -> String? {
        let documentId = approvalId / 10
        let status = decision == "REJECT" ? "REJECTED" : "APPROVED"
        guard update(id: documentId, status: status, now: now) else { return nil }
        if let comment, !comment.isEmpty {
            _ = appendComment(documentId: documentId, body: comment, now: now)
        }
        struct Result: Encodable {
            let status: String
            let nextApproverName: String?
        }
        return encode(Result(status: status, nextApproverName: status == "APPROVED" ? "김민준" : nil), message: "처리 완료")
    }

    func commentJSON(documentId: Int, body: String, now: Date = Date()) -> String? {
        guard let comment = appendComment(documentId: documentId, body: body, now: now) else { return nil }
        return encode(comment, message: "등록 완료")
    }

    private func appendComment(documentId: Int, body: String, now: Date) -> Comment? {
        lock.lock()
        defer { lock.unlock() }
        guard storage.contains(where: { $0.id == documentId }) else { return nil }
        nextCommentId += 1
        let comment = Comment(id: nextCommentId, authorName: "홍길동", body: body, createdAt: ISO8601DateFormatter().string(from: now))
        comments[documentId, default: []].append(comment)
        return comment
    }
}
