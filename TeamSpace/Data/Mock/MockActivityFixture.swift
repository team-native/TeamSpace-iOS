import Foundation

/// 내 활동 가짜 응답 — 서버 develop `GET /me/activity` 형식, Figma 07-10 예시 댓글 (날짜는 오늘 기준)
/// 내가 쓴 글 · 제안은 MockBoardStore · MockProposalStore 의 `mine` 항목을 그대로 써요.
enum MockActivityFixture {
    /// 07-12 숫자 중 아직 다른 Mock 저장소가 없는 것
    static let postCount = 3
    static let inquiryCount = 2

    private static func date(_ daysAgo: Double, hour: Double, now: Date) -> String {
        let today = Calendar.current.startOfDay(for: now)
        return ISO8601DateFormatter().string(from: today.addingTimeInterval(-daysAgo * 86_400 + hour * 3_600))
    }

    /// GET /me/activity — 최근 순 `{id, kind, title, createdAt, href}` (댓글 4 · 그 밖의 활동 2)
    static func activity(now: Date = Date()) -> String {
        func at(_ days: Double, _ hour: Double) -> String { date(days, hour: hour, now: now) }
        let items: [[String: Any]] = [
            ["id": "301", "kind": "comment", "title": "예약 기준이 정리되면 좋겠어요.", "createdAt": at(2, 17.08), "href": "/inhouse/board/22"],
            ["id": "300", "kind": "todo", "title": "디자인 QA 체크리스트 정리", "createdAt": at(2, 18), "href": ""],
            ["id": "299", "kind": "comment", "title": "다음 주엔 제가 한 권 가져올게요!", "createdAt": at(3, 20), "href": "/inhouse/board/31"],
            ["id": "290", "kind": "comment", "title": "멘토링 공유 시간이 특히 좋았어요.", "createdAt": at(6, 16.5), "href": ""],
            ["id": "285", "kind": "approval", "title": "Figma 팀 플랜 갱신", "createdAt": at(7, 9), "href": ""],
            ["id": "281", "kind": "comment", "title": "중복 구독은 분기마다 확인하면 좋겠어요.", "createdAt": at(9, 11), "href": ""]
        ]
        let object: [String: Any] = ["items": items, "nextCursor": NSNull()]
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}
