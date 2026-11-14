import Foundation

/// GET /people · /people/{id} 가짜 응답 — Figma 03 팀원 예시를 서버 develop 형식(`user_profile`)으로
enum MockMemberFixture {
    /// 2026년 3월 2일 (2기 합류)
    private static let firstDay = Date(timeIntervalSince1970: 1_772_409_600)

    private static func people(now: Date) -> [[String: Any]] {
        let rows: [(String, String, [String], String, String)] = [
            ("이시우", "Leader", ["Leader"], "Leader", "Native 총괄"),
            ("양지우", "NativeOps", ["Member"], "StudyLeader", "운영 · 제도"),
            ("안율", "NativeOps", ["Member"], "OL", "운영 · 공지"),
            ("오잉", "PMO", ["PM"], "PM", "프로젝트 매니저"),
            ("김민준", "FA", ["FA"], "FA", "재무 · 회계"),
            ("옥물결", "Design", ["Member"], "Design", "UI Designer"),
            ("이채율", "Dev", ["Member"], "Dev", "iOS Engineer"),
            ("김민규", "Dev", ["Member"], "Dev", "Web Engineer"),
            ("카피바라", "Design", ["Member"], "Design", "Product Designer"),
            ("박서연", "PMO", ["PM"], "PM", "프로젝트 매니저"),
            ("최도윤", "PMO", ["Member"], "PMO", "인력 배치"),
            ("한서진", "Design", ["Member"], "Design", "UX Researcher"),
            ("윤하늘", "Design", ["Member"], "Design", "Graphic Designer"),
            ("송지호", "Dev", ["Member"], "Dev", "Android Engineer"),
            ("장유나", "Dev", ["Member"], "Dev", "Backend Engineer"),
            ("임도현", "Dev", ["Member"], "Dev", "iOS Engineer"),
            ("서지안", "Design", ["Member"], "Design", "Brand Designer"),
            ("강태오", "Dev", ["Member"], "Dev", "Web Engineer"),
            ("배수아", "Dev", ["Member"], "Dev", "QA Engineer"),
            ("문채원", "Design", ["Member"], "Design", "UI Designer"),
            ("조현우", "Dev", ["Member"], "Dev", "Backend Engineer"),
            ("남궁별", "Dev", ["Member"], "Dev", "iOS Engineer"),
            ("유다인", "NativeOps", ["Member"], "OL", "행사 · 홍보"),
            ("홍길동", "PMO", ["Member"], "PMO", "일정 관리")
        ]
        let iso = ISO8601DateFormatter()
        return rows.enumerated().map { index, row in
            let id = index + 1
            let isFigmaSample = row.0 == "오잉"
            // 마지막 두 명은 조직도에만 있고 아직 계정이 없어요. (가입 승인 때 연결)
            let hasAccount = id <= rows.count - 2
            // 카피바라 님은 이번 주에 합류 (Figma 02-3 "이번 주 새 멤버")
            let joined = row.0 == "카피바라" ? now.addingTimeInterval(-2 * 86_400) : firstDay
            let projects: [[String]] = isFigmaSample ? [
                ["Book-on", "PM · 진행 중"],
                ["Native 팀스페이스", "PMO · 진행 중"],
                ["MoSS", "리뷰 · 완료"]
            ] : [["Native 팀스페이스", row.3]]
            return [
                "id": String(id),
                "name": row.0,
                "email": isFigmaSample ? "s26099@gsm.hs.kr" : "s26\(String(format: "%03d", 100 + id))@gsm.hs.kr",
                "dept": row.1,
                "role": row.4,
                "major": row.4,
                "cohort": "2기",
                "github": "",
                "photo": "",
                "joined": iso.string(from: joined),
                "bio": isFigmaSample ? "일정은 함께 지키는 약속이에요." : "",
                "interests": isFigmaSample ? ["앱개발", "코레일", "닭발", "밥 먹기", "카피바라 키우기 게임"] : ["앱개발"],
                "projects": projects,
                "isNew": now.timeIntervalSince(joined) < 7 * 86_400,
                "lead": row.2.contains("Leader"),
                "roles": row.2,
                "linked": hasAccount,
                "userId": hasAccount ? String(id) as Any : NSNull()
            ]
        }
    }

    /// 서버처럼 id 순, `cursor` 보다 큰 id 부터 `limit` 개
    static func list(cursor: Int?, limit: Int, now: Date = Date()) -> String {
        let all = people(now: now)
        let start = cursor ?? 0
        let rest = all.filter { Int($0["id"] as? String ?? "") ?? 0 > start }
        let page = Array(rest.prefix(limit))
        let next = rest.count > limit ? page.last?["id"] : nil
        return envelope(["items": page, "nextCursor": next ?? NSNull()])
    }

    /// GET /admin/users — 계정이 있는 사람만, 관리자 목록 형식으로 (Mock 은 조직도 id 가 없어요)
    static func adminUsers(cursor: String?, limit: Int, now: Date = Date()) -> String {
        let accounts = people(now: now).filter { !($0["userId"] is NSNull) }.map { person -> [String: Any] in
            let roles = person["roles"] as? [String] ?? []
            return [
                "id": person["id"] ?? "", "userId": person["userId"] ?? "", "memberId": NSNull(),
                "name": person["name"] ?? "", "email": person["email"] ?? "", "dept": person["dept"] ?? "",
                "roles": roles, "active": true, "inOrganization": false, "isAdmin": roles.contains("Admin")
            ]
        }
        let start = cursor.flatMap { id in accounts.firstIndex { $0["userId"] as? String == id }.map { $0 + 1 } } ?? 0
        let rest = Array(accounts.dropFirst(start))
        let page = Array(rest.prefix(limit))
        let next = rest.count > limit ? page.last?["userId"] : nil
        return envelope(["items": page, "nextCursor": next ?? NSNull()])
    }

    static func detail(id: Int, now: Date = Date()) -> String? {
        people(now: now).first { $0["id"] as? String == String(id) }.map(envelope)
    }

    private static func envelope(_ data: Any) -> String {
        let body = (try? JSONSerialization.data(withJSONObject: data, options: .sortedKeys)) ?? Data("{}".utf8)
        return #"{"code":200,"message":"OK","data":"# + String(decoding: body, as: UTF8.self) + "}"
    }
}
