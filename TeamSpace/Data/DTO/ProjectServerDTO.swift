import Foundation

/// GET /projects 한 항목 · GET /projects/{id} (TeamSpace-backend `space.py`, 프런트 `Project`)
/// `{ id(slug), name, desc, role, progress, status, due, milestone, pm, dept, members, openings, updatedAt }`
struct ServerProjectDTO: Decodable {
    let id: String
    let name: String
    let desc: String
    let progress: Int
    let status: String
    let due: String?
    let pm: String
    let dept: String
    let members: [ServerProjectMemberDTO]
    let openings: [ServerProjectOpeningDTO]
    let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, name, desc, progress, status, due, pm, dept, department, members, openings, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? container.decode(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        desc = (try? container.decodeIfPresent(String.self, forKey: .desc)) ?? ""
        progress = container.money(.progress)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        due = try? container.decodeIfPresent(String.self, forKey: .due)
        pm = (try? container.decodeIfPresent(String.self, forKey: .pm)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept))
            ?? (try? container.decodeIfPresent(String.self, forKey: .department)) ?? ""
        members = (try? container.decodeIfPresent([ServerProjectMemberDTO].self, forKey: .members)) ?? []
        openings = (try? container.decodeIfPresent([ServerProjectOpeningDTO].self, forKey: .openings)) ?? []
        updatedAt = (try? container.decodeIfPresent(String.self, forKey: .updatedAt)).flatMap { ServerDate.parse($0) }
    }

    /// "독서 기록 앱 · 그린랩 외주 · 2026.08 – 2026.11" → 설명 · 기간
    private var descParts: (summary: String, period: (Date?, Date?)) {
        let parts = desc.components(separatedBy: " · ")
        guard let last = parts.last, parts.count > 1, let period = Self.period(last) else { return (desc, (nil, nil)) }
        return (parts.dropLast().joined(separator: " · "), period)
    }

    /// "2026.08 – 2026.11" · "2026.06 –" → (8월 1일, 11월 말일)
    static func period(_ text: String, calendar: Calendar = .current) -> (Date?, Date?)? {
        let sides = text.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespaces) }
        func month(_ value: String) -> Date? {
            let numbers = value.split(separator: ".").compactMap { Int($0) }
            guard numbers.count >= 2 else { return nil }
            return calendar.date(from: DateComponents(year: numbers[0], month: numbers[1], day: numbers.count > 2 ? numbers[2] : 1))
        }
        guard let first = sides.first, let start = month(first) else { return nil }
        let end = sides.count > 1 ? month(sides[1]).flatMap { date -> Date? in
            sides[1].split(separator: ".").count > 2 ? date : calendar.date(byAdding: DateComponents(month: 1, day: -1), to: date)
        } : nil
        return (start, end)
    }

    /// "11.20 납품" → 그날 (연도는 기간 끝 해, 없으면 올해)
    static func dueDate(_ text: String?, year: Int?, calendar: Calendar = .current) -> Date? {
        guard let text else { return nil }
        let numbers = text.prefix(5).split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 2 else { return nil }
        return calendar.date(from: DateComponents(year: year ?? calendar.component(.year, from: Date()), month: numbers[0], day: numbers[1]))
    }

    func toEntity(calendar: Calendar = .current) -> ProjectSummary {
        let (summary, period) = descParts
        let endYear = period.1.map { calendar.component(.year, from: $0) }
        return ProjectSummary(
            id: id,
            name: name,
            summary: summary,
            department: dept,
            pmName: pm,
            memberCount: members.count,
            status: ProjectRunStatus(serverValue: status),
            startDate: period.0,
            endDate: Self.dueDate(due, year: endYear, calendar: calendar) ?? period.1,
            progress: progress,
            openings: openings.enumerated().map { $0.element.toEntity(id: $0.offset + 1) },
            resultNote: nil,
            updatedAt: updatedAt ?? .distantPast,
            dueText: due.flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    func toDetail(isJoined: Bool) -> ProjectDetail {
        ProjectDetail(
            project: toEntity(),
            members: members.map { ProjectMember(id: $0.key, name: $0.key, role: $0.role) },
            relatedItems: [],
            isJoined: isJoined
        )
    }
}

/// 함께하는 사람 — 프런트 `[key, role]`, 서버 기본값 `[userId, major]`, 객체 `{ id|name, role }`
struct ServerProjectMemberDTO: Decodable {
    let key: String
    let role: String

    private enum CodingKeys: String, CodingKey { case id, name, role }

    init(from decoder: Decoder) throws {
        if let pair = try? decoder.singleValueContainer().decode([String].self) {
            key = pair.first ?? ""
            role = pair.count > 1 ? pair[1] : ""
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? container.decodeIfPresent(String.self, forKey: .name))
            ?? (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        role = (try? container.decodeIfPresent(String.self, forKey: .role)) ?? ""
    }
}

/// 모집 자리 — 프런트 `["Web 프론트엔드", "1명 · 관리자 페이지 · 주 6시간"]`, 객체 `{ role|position, title, count|headcount, period, description }`
struct ServerProjectOpeningDTO: Decodable {
    let role: String
    let title: String
    let headcount: Int
    let detail: String

    private enum CodingKeys: String, CodingKey { case role, position, title, count, headcount, remaining, period, description, detail }

    init(from decoder: Decoder) throws {
        if let pair = try? decoder.singleValueContainer().decode([String].self) {
            role = pair.first ?? ""
            title = role
            let text = pair.count > 1 ? pair[1] : ""
            let parts = text.components(separatedBy: " · ")
            if let first = parts.first, first.hasSuffix("명"), let count = Int(first.filter(\.isNumber)) {
                headcount = count
                detail = parts.dropFirst().joined(separator: " · ")
            } else {
                headcount = 1
                detail = text
            }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = (try? container.decodeIfPresent(String.self, forKey: .role))
            ?? (try? container.decodeIfPresent(String.self, forKey: .position)) ?? ""
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? role
        let count = [CodingKeys.count, .headcount, .remaining].lazy.map { container.money($0) }.first { $0 > 0 }
        headcount = count ?? 1
        detail = [
            try? container.decodeIfPresent(String.self, forKey: .period),
            (try? container.decodeIfPresent(String.self, forKey: .description))
                ?? (try? container.decodeIfPresent(String.self, forKey: .detail))
        ].compactMap { $0 ?? nil }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// 자리 설명에 "11.01 – 11.15" 같은 기간이 있으면 읽어요.
    func toEntity(id: Int, calendar: Calendar = .current) -> ProjectOpening {
        let range = detail.components(separatedBy: " · ").lazy.compactMap { part -> (Date?, Date?)? in
            let sides = part.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespaces) }
            guard sides.count == 2 else { return nil }
            let year = calendar.component(.year, from: Date())
            return (ServerProjectDTO.dueDate(sides[0], year: year), ServerProjectDTO.dueDate(sides[1], year: year))
        }.first { $0.0 != nil }
        return ProjectOpening(
            id: id, role: role, title: title, headcount: headcount,
            startDate: range?.0, endDate: range?.1, description: detail
        )
    }
}

/// GET /projects 응답 — `{ items, nextCursor, total }`
struct ServerProjectPageDTO: Decodable {
    let items: [ServerProjectDTO]
    let nextCursor: String?
}

/// GET /me/projects — 참여 여부만 봐요. (id 는 레코드 번호, slug 는 payload 에 있을 수 있어요)
struct ServerMyProjectRefDTO: Decodable {
    let id: String?
    let slug: String?
    let name: String?

    private enum CodingKeys: String, CodingKey { case id, slug, name }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? (try? container.decode(Int.self, forKey: .id)).map(String.init)
        slug = try? container.decodeIfPresent(String.self, forKey: .slug)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
    }

    func matches(_ project: ServerProjectDTO) -> Bool {
        [id, slug].contains(project.id) || name == project.name
    }
}

/// POST /projects/{id}/apply 요청 — 서버는 `position` 또는 `role` 이 꼭 있어야 해요.
struct ServerApplyRequestDTO: Encodable {
    let position: String
    let openingId: Int
    let availability: String
    let message: String

    init(_ draft: ApplicationDraft) {
        position = draft.position
        openingId = draft.openingId
        availability = draft.availability.rawValue
        message = draft.message
    }
}

/// POST /projects/{id}/apply 응답 — `{ applicationId, status: "APPLIED" }`
struct ServerApplyResultDTO: Decodable {
    let applicationId: Int

    private enum CodingKeys: String, CodingKey { case applicationId }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try container.decodeIntOrString(forKey: .applicationId)
    }
}
