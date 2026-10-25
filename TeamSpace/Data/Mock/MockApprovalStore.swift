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

    private let lock = NSLock()
    private var storage: [Item]

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
}
