import Foundation

/// GET /people 한 항목 · GET /people/{id} (TeamSpace-backend develop `shared.user_profile`)
/// `{ id: "4", name, email, dept, role(=major), cohort, github, joined, bio, interests, projects: [[name, role]], isNew, lead, roles }`
struct ServerPersonDTO: Decodable {
    let id: Int
    let name: String
    let email: String
    let dept: String
    let role: String
    let cohort: String
    let joined: Date?
    let bio: String
    let interests: [String]
    let projects: [[String]]
    let lead: Bool
    let roles: [UserRole]

    private enum CodingKeys: String, CodingKey {
        case id, name, email, dept, department, role, major, cohort, joined, bio, interests, projects, lead, roles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        email = (try? container.decodeIfPresent(String.self, forKey: .email)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept))
            ?? (try? container.decodeIfPresent(String.self, forKey: .department)) ?? ""
        let role = (try? container.decodeIfPresent(String.self, forKey: .role)) ?? ""
        self.role = role.isEmpty ? ((try? container.decodeIfPresent(String.self, forKey: .major)) ?? "") : role
        cohort = (try? container.decodeIfPresent(String.self, forKey: .cohort))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .cohort)).map { String($0) } ?? ""
        joined = (try? container.decodeIfPresent(String.self, forKey: .joined)).flatMap { $0.flatMap(ServerDate.parse) }
        bio = (try? container.decodeIfPresent(String.self, forKey: .bio)) ?? ""
        interests = (try? container.decodeIfPresent([String].self, forKey: .interests)) ?? []
        projects = (try? container.decodeIfPresent([[String]].self, forKey: .projects)) ?? []
        lead = (try? container.decodeIfPresent(Bool.self, forKey: .lead)) ?? false
        roles = (try? container.decodeIfPresent([UserRole].self, forKey: .roles)) ?? []
    }

    var department: Department { Department(serverDept: dept, roles: roles) }

    /// 이름 옆 칩 — 서버에 따로 없어 역할 · 부서로 정해요.
    var tag: String {
        if roles.contains(.leader) { return "Leader" }
        if roles.contains(.pm) { return "PM" }
        if roles.contains(.fa) { return "FA" }
        if department == .nativeOps { return "OL" }
        return dept
    }

    func toEntity() -> Member {
        Member(
            id: id, name: name, department: department, roles: roles, tag: tag,
            position: role, joinedAt: joined ?? .distantPast
        )
    }

    /// 참여 프로젝트 `["Book-on", "iOS 개발 · 진행 중"]` → 역할 "iOS 개발", 상태 진행 중
    func toDetail() -> MemberDetail {
        MemberDetail(
            member: toEntity(),
            email: email,
            responsibility: role,
            generation: Int(cohort.filter(\.isNumber)),
            statusMessage: bio.isEmpty ? nil : bio,
            projects: projects.enumerated().compactMap { index, pair in
                guard let name = pair.first, !name.isEmpty else { return nil }
                var parts = (pair.count > 1 ? pair[1] : "").components(separatedBy: " · ")
                var status = MemberProject.Status.inProgress
                if let last = parts.last, parts.count > 1, last.contains("완료") || last.contains("진행") {
                    status = last.contains("완료") ? .completed : .inProgress
                    parts.removeLast()
                }
                return MemberProject(id: index + 1, name: name, summary: "", role: parts.joined(separator: " · "), status: status)
            },
            interests: interests
        )
    }
}

extension Department {
    /// 서버 `dept` 는 자유 문자열이라 이름으로 맞춰요. ("Core Platform" · "NativeLab" 은 개발)
    init(serverDept: String, roles: [UserRole] = []) {
        let text = serverDept.trimmingCharacters(in: .whitespaces).lowercased()
        switch text {
        case "leader": self = .leader
        case "nativeops", "ol", "운영": self = .nativeOps
        case "pmo", "pm": self = .pmo
        case "fa", "재무": self = .fa
        case "design", "native", "디자인": self = .design
        case "dev", "nativelab", "core platform", "개발": self = .dev
        default:
            self = roles.contains(.leader) ? .leader : .unknown
        }
    }
}

/// 조직도 — 서버 `/organization/tree` 는 옛 형식이라, /people 을 부서별로 묶어 만들어요. (Figma 03-2 문구)
enum OrganizationTreeBuilder {
    static let units: [(Department, String, String)] = [
        (.nativeOps, "NativeOps", "운영 · 제도 · 공지 관리"),
        (.pmo, "PM", "프로젝트 일정과 인력 배치"),
        (.fa, "FA", "재무 · 회계 · 정산"),
        (.design, "NativeLab · Design", "프로덕트 · UI 디자인"),
        (.dev, "NativeLab · Dev", "iOS · Web 개발")
    ]

    static func build(_ members: [Member]) -> OrganizationTree? {
        guard let leader = members.first(where: { $0.department == .leader }) ?? members.first(where: { $0.roles.contains(.leader) })
        else { return nil }
        return OrganizationTree(
            leader: leader,
            units: units.enumerated().map { index, unit in
                OrganizationUnit(
                    id: index + 1, name: unit.1, summary: unit.2, department: unit.0,
                    members: members.filter { $0.department == unit.0 && $0.id != leader.id }
                )
            }
        )
    }
}
