import Foundation

/// GET /dashboard/home 가짜 응답 — Figma 02-1 홈 예시를 서버 develop 형식으로.
/// 날짜는 오늘 기준으로 만들어서 D-day 가 항상 자연스럽게 보이게 합니다.
/// `finance` 는 FA 일 때만 넣어요. (금액 흐름은 /finance/summary 가 줘요)
enum MockDashboardFixture {
    static func json(now: Date = Date(), isFA: Bool, calendar: Calendar = .current) -> String {
        let iso = ISO8601DateFormatter()
        func later(_ days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: now) ?? now }
        func day(_ days: Int) -> String {
            let parts = calendar.dateComponents([.year, .month, .day], from: later(days))
            return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        }
        func due(_ days: Int) -> String {
            let parts = calendar.dateComponents([.month, .day], from: later(days))
            return String(format: "%02d.%02d 납품", parts.month ?? 0, parts.day ?? 0)
        }
        var data: [String: Any] = [
            "me": ["id": 1, "name": "옥물결", "dept": "Core Platform"],
            "summary": [
                "todoCount": 5,
                "todayTodoCount": 3,
                "unreadNotifications": 3,
                "receivedApprovalCount": 1,
                "notice": [
                    "id": "41", "kind": "재무", "title": "10월 프로젝트 정산 기준 안내",
                    "createdAt": iso.string(from: later(-1)), "updatedAt": iso.string(from: later(-1))
                ],
                "schedule": ["id": "31", "title": "주간 팀 회의", "date": day(1), "time": "19:00", "place": "온라인"]
            ],
            "todos": [],
            "notifications": [[
                "id": "101", "kind": "내 업무", "sourceKind": "내 업무", "title": "이시우님이 'Book-on 인력 지원' 결재를 요청했어요",
                "createdAt": iso.string(from: now.addingTimeInterval(-30)), "href": "/inhouse/requests/12",
                "unread": true, "action": true
            ]],
            "approvals": [],
            "events": [
                ["id": "31", "title": "주간 팀 회의", "date": day(1), "time": "19:00", "place": "온라인"],
                ["id": "32", "title": "IoT 학과 홍보 홈페이지 납품", "date": day(12), "place": "내부 운영 플랫폼"]
            ],
            "projects": [
                [
                    "id": "21", "name": "먼작귀 포켓앱 UI 제작", "desc": "캐릭터 굿즈 앱 · 외주", "due": due(27),
                    "progress": 35, "pm": "박도윤", "dept": "Design", "members": ["a", "b", "c", "d", "e"]
                ],
                [
                    "id": "22", "name": "MoSS", "desc": "모바일 서비스 · 내부", "due": due(14),
                    "progress": 60, "pm": "최하은", "dept": "Core Platform", "members": ["a", "b", "c", "d", "e", "f"]
                ]
            ]
        ]
        if isFA {
            data["finance"] = [
                "available": 3_560_000,
                "pools": [
                    ["id": "operation", "amount": 3_560_000, "ratio": 40],
                    ["id": "reserve", "amount": 2_670_000, "ratio": 30],
                    ["id": "dividend", "amount": 2_670_000, "ratio": 30]
                ]
            ]
        }
        let body = (try? JSONSerialization.data(withJSONObject: data, options: .sortedKeys)) ?? Data("{}".utf8)
        return #"{"code":200,"message":"OK","data":"# + String(decoding: body, as: UTF8.self) + "}"
    }
}
