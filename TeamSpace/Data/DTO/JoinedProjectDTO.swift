import Foundation

/// GET /me/projects 의 한 항목 — `{id, ...프로젝트 payload}` (TeamSpace-backend develop `space.my_projects`)
/// 기간 필드가 없어 `desc`("독서 기록 앱 · 그린랩 외주 · 2026.08 – 2026.11")의 기간을 읽고, 없으면 `due` 를 보여줘요.
struct ServerJoinedProjectDTO: Decodable {
    let id: Int
    let name: String
    let desc: String
    let due: String
    let status: String
    let pm: String
    let dept: String
    let progress: Int
    let memberCount: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        desc = (try? container.decodeIfPresent(String.self, forKey: .description))
            ?? (try? container.decodeIfPresent(String.self, forKey: .desc)) ?? ""
        due = (try? container.decodeIfPresent(String.self, forKey: .due)) ?? ""
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "진행 중"
        pm = (try? container.decodeIfPresent(String.self, forKey: .pm)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        progress = (try? container.decodeIfPresent(Int.self, forKey: .progress)) ?? 0
        let memberIds = (try? container.decodeIfPresent([IgnoredJSONValue].self, forKey: .memberIds)) ?? nil
        let members = (try? container.decodeIfPresent([IgnoredJSONValue].self, forKey: .members)) ?? nil
        memberCount = max(memberIds?.count ?? 0, members?.count ?? 0)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, desc, description, due, status, pm, dept, progress, memberIds, members
    }

    /// 07-1 홈 참여 프로젝트 카드
    func toWorkspaceProject() -> WorkspaceProject {
        WorkspaceProject(id: id, name: name, pmName: pm, team: dept, memberCount: memberCount, progress: min(max(progress, 0), 100))
    }

    func toEntity() -> JoinedProject {
        let parts = desc.components(separatedBy: " · ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let periodIndex = parts.lastIndex { $0.range(of: #"^\d{4}\.\d{1,2}"#, options: .regularExpression) != nil }
        let period = periodIndex.map { parts[$0] } ?? (due.isEmpty ? nil : due)
        return JoinedProject(
            id: id,
            name: name,
            summary: parts.first { $0 != periodIndex.map { parts[$0] } } ?? "",
            period: period,
            status: ProjectRunStatus(serverValue: status)
        )
    }
}

extension ProjectRunStatus {
    /// 진행 중 · 마무리 → 진행 중, 완료 → 완료, 예정 · 모집 중 → 예정
    init(serverValue: String) {
        switch serverValue {
        case "진행 중", "진행중", "마무리": self = .inProgress
        case "완료": self = .completed
        case "예정", "모집 중", "준비 중": self = .planned
        default: self = ProjectRunStatus(rawValue: serverValue) ?? .unknown
        }
    }
}
