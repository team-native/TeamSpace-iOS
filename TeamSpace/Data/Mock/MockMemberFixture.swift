import Foundation

/// GET /users · /users/{id} · /organization/tree 가짜 응답 — Figma 03 팀원 예시 내용
enum MockMemberFixture {
    private struct MemberItem: Encodable {
        let id: Int
        let name: String
        let department: String
        let roles: [String]
        let tag: String
        let position: String
        let joinedAt: Date
    }

    private struct DetailItem: Encodable {
        let id: Int
        let name: String
        let department: String
        let roles: [String]
        let tag: String
        let position: String
        let joinedAt: Date
        let email: String
        let responsibility: String
        let generation: Int
        let statusMessage: String?
        let projects: [ProjectItem]
        let interests: [String]
    }

    private struct ProjectItem: Encodable {
        let id: Int
        let name: String
        let summary: String
        let role: String
        let status: String
    }

    private struct UnitItem: Encodable {
        let id: Int
        let name: String
        let summary: String
        let department: String
        let members: [MemberItem]
    }

    private struct TreeItem: Encodable {
        let leader: MemberItem
        let units: [UnitItem]
    }

    private struct Envelope<T: Encodable>: Encodable {
        let code: Int
        let message: String
        let data: T
    }

    /// 2026년 3월 2일 (2기 합류)
    private static let firstDay = Date(timeIntervalSince1970: 1_772_409_600)

    private static func members(now: Date) -> [MemberItem] {
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
        return rows.enumerated().map { index, row in
            MemberItem(
                id: index + 1,
                name: row.0,
                department: row.1,
                roles: row.2,
                tag: row.3,
                position: row.4,
                // 카피바라 님은 이번 주에 합류 (Figma 02-3 "이번 주 새 멤버")
                joinedAt: row.0 == "카피바라" ? now.addingTimeInterval(-2 * 86_400) : firstDay
            )
        }
    }

    static func list(now: Date = Date()) -> Data? {
        encode(["list": members(now: now)])
    }

    static func detail(id: Int, now: Date = Date()) -> Data? {
        guard let member = members(now: now).first(where: { $0.id == id }) else { return nil }
        let isFigmaSample = member.name == "오잉"
        let projects = isFigmaSample ? [
            ProjectItem(id: 1, name: "Book-on", summary: "독서 기록 앱", role: "PM", status: "IN_PROGRESS"),
            ProjectItem(id: 2, name: "Native 팀스페이스", summary: "내부 운영 플랫폼", role: "PMO", status: "IN_PROGRESS"),
            ProjectItem(id: 3, name: "MoSS", summary: "관리자 도구", role: "리뷰", status: "COMPLETED")
        ] : [
            ProjectItem(id: 2, name: "Native 팀스페이스", summary: "내부 운영 플랫폼", role: member.tag, status: "IN_PROGRESS")
        ]
        let detail = DetailItem(
            id: member.id,
            name: member.name,
            department: member.department,
            roles: member.roles,
            tag: member.tag,
            position: member.position,
            joinedAt: member.joinedAt,
            email: isFigmaSample ? "s26099@gsm.hs.kr" : "s26\(String(format: "%03d", 100 + member.id))@gsm.hs.kr",
            responsibility: isFigmaSample ? "프로젝트 일정 · 인력 관리" : member.position,
            generation: 2,
            statusMessage: isFigmaSample ? "일정은 함께 지키는 약속이에요." : nil,
            projects: projects,
            interests: isFigmaSample ? ["앱개발", "코레일", "닭발", "밥 먹기", "카피바라 키우기 게임"] : ["앱개발"]
        )
        return encode(detail)
    }

    static func tree(now: Date = Date()) -> Data? {
        let all = members(now: now)
        guard let leader = all.first(where: { $0.department == "Leader" }) else { return nil }
        let units: [(String, String, String)] = [
            ("NativeOps", "NativeOps", "운영 · 제도 · 공지 관리"),
            ("PMO", "PM", "프로젝트 일정과 인력 배치"),
            ("FA", "FA", "재무 · 회계 · 정산"),
            ("Design", "NativeLab · Design", "프로덕트 · UI 디자인"),
            ("Dev", "NativeLab · Dev", "iOS · Web 개발")
        ]
        let tree = TreeItem(
            leader: leader,
            units: units.enumerated().map { index, unit in
                UnitItem(
                    id: index + 1,
                    name: unit.1,
                    summary: unit.2,
                    department: unit.0,
                    members: all.filter { $0.department == unit.0 }
                )
            }
        )
        return encode(tree)
    }

    private static func encode<T: Encodable>(_ data: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(Envelope(code: 200, message: "조회 성공", data: data))
    }
}
