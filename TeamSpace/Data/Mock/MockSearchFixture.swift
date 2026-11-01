import Foundation

/// GET /search — Figma 13 통합 검색 예시 ("Book-on")
/// 검색어가 제목 · 내용 · 작성자 · PM 에 들어 있는 것만 돌려줘요. 익명 글 · 익명 제안은 처음부터 넣지 않아요.
enum MockSearchFixture {
    private struct Item {
        let category: String
        let id: String
        let title: String
        let snippet: String
        let createdAt: String
        var extra: [String: Any] = [:]

        var haystack: String {
            ([title, snippet] + extra.values.compactMap { $0 as? String }).joined(separator: " ")
        }

        var json: [String: Any] {
            var object: [String: Any] = ["category": category, "id": id, "title": title, "snippet": snippet, "createdAt": createdAt]
            object.merge(extra) { _, new in new }
            return object
        }
    }

    private static let items: [Item] = [
        Item(category: "documents", id: "7", title: "Book-on QA 체크리스트",
             snippet: "10.23 QA 점검을 위한 테스트 항목과 담당 업무를 확인해요.", createdAt: "2026-10-15T09:00:00.000+00:00",
             extra: ["type": "PROJECT", "version": 2]),
        Item(category: "documents", id: "1", title: "프로젝트 운영 원칙 v1.3",
             snippet: "Book-on 등 프로젝트의 제안 검토 기한: 3주 → 2주", createdAt: "2026-10-11T09:00:00+00:00",
             extra: ["type": "RULE", "version": "v1.3"]),
        Item(category: "projects", id: "1", title: "Book-on",
             snippet: "독서 기록과 습관 만들기를 돕는 iOS 앱", createdAt: "2026-07-01T00:00:00+00:00",
             extra: ["dept": "NativeLab", "pm": "이시우", "progress": 68]),
        Item(category: "people", id: "1", title: "이시우",
             snippet: "Leader · Book-on PM", createdAt: "2026-03-02T00:00:00+00:00"),
        Item(category: "posts", id: "40", title: "회식 이시우가 쏘는 거 어떤가요?",
             snippet: "Book-on 출시 기념으로 이시우가 쏘는 게 합당하다고 생각합니다.", createdAt: "2026-10-15T11:00:00+00:00",
             extra: ["author": "김민준", "comments": 2]),
        Item(category: "proposals", id: "11", title: "회의 기록 양식을 통일해요",
             snippet: "회의 기록 양식을 통일시키면 더욱 보기 편할 것 같아요. Book-on 회의부터 시범 적용해요.",
             createdAt: "2026-10-07T09:00:00+00:00",
             extra: ["author": "옥물결", "status": "IN_REVIEW", "likes": 18])
    ]

    /// `offset` · `limit` 은 서버의 `cursor` · `limit` 과 같아요 (커서 = 다음 시작 위치).
    static func search(query: String, offset: Int = 0, limit: Int = 50) -> String {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = items.filter { $0.haystack.localizedCaseInsensitiveContains(needle) }
        var counts: [String: Int] = ["documents": 0, "projects": 0, "people": 0, "posts": 0, "proposals": 0]
        for item in matched { counts[item.category, default: 0] += 1 }
        let start = min(max(offset, 0), matched.count)
        let end = min(start + max(limit, 1), matched.count)
        let page = matched[start..<end]
        let data: [String: Any] = [
            "query": needle,
            "items": page.map(\.json),
            "counts": counts,
            "nextCursor": end < matched.count ? String(end) as Any : NSNull()
        ]
        let body: [String: Any] = ["code": 200, "message": "OK", "data": data]
        guard
            let json = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]),
            let text = String(data: json, encoding: .utf8)
        else { return #"{"code":500,"message":"검색 예시를 만들지 못했어요.","data":null}"# }
        return text
    }
}
