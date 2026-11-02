import Foundation

/// GET /todos 의 한 항목 (TeamSpace-backend develop `space._todo_item`)
/// 받은 결재는 서버가 `approval:{결재 id}` 로 만들어 붙여요. (저장된 할 일이 아니에요)
struct ServerTodoDTO: Decodable {
    static let approvalPrefix = "approval:"

    let rawId: String
    let title: String
    /// YYYY-MM-DD
    let dueDate: String?
    /// 시각까지 정한 할 일 (ISO8601)
    let dueAt: String?
    let projectName: String?
    /// 개인 업무 · 프로젝트 업무 · 결재 · 일정
    let category: String?
    /// 미완료 · 예정 · 완료
    let status: String?
    let completedAt: Date?
    let createdAt: Date?
    let sourceId: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? container.decode(Int.self, forKey: .id) {
            rawId = String(number)
        } else {
            rawId = try container.decode(String.self, forKey: .id)
        }
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        dueDate = try? container.decodeIfPresent(String.self, forKey: .dueDate)
        dueAt = try? container.decodeIfPresent(String.self, forKey: .dueAt)
        projectName = try? container.decodeIfPresent(String.self, forKey: .projectName)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        completedAt = try? container.decodeIfPresent(Date.self, forKey: .completedAt)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        sourceId = try? container.decodeIfPresent(String.self, forKey: .sourceId)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, dueDate, dueAt, projectName, category, status, completedAt, createdAt, sourceId
    }

    /// 결재 할 일은 결재 id 를 음수로 써요. (서버에 저장된 할 일이 아니라 완료 상태를 보낼 수 없어요)
    var id: Int? {
        if rawId.hasPrefix(Self.approvalPrefix) {
            return Int(rawId.dropFirst(Self.approvalPrefix.count)).map { -$0 }
        }
        return Int(rawId)
    }

    func toEntity() -> TodoItem? {
        guard let id else { return nil }
        let timed = dueAt.flatMap { $0.isEmpty ? nil : ServerDate.parse($0) }
        let day = dueDate.flatMap(Self.date(fromDay:))
        let kind = TodoLinkKind(serverCategory: category)
        return TodoItem(
            id: id,
            title: title,
            dueAt: timed ?? day ?? createdAt ?? Date(),
            hasTime: timed != nil,
            endsAt: nil,
            place: nil,
            projectName: projectName.flatMap { $0.isEmpty ? nil : $0 },
            linkKind: kind,
            linkedId: sourceId.flatMap(Int.init) ?? (id < 0 ? -id : nil),
            status: status == "완료" ? .done : .open,
            completedAt: completedAt
        )
    }

    /// "2026-10-20" → 서울 기준 그날 0시
    static func date(fromDay text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }
}

/// POST /todos 요청 — 빠르게 추가는 날짜만 정해요.
struct ServerTodoCreateRequestDTO: Codable, Equatable {
    let title: String
    let dueDate: String
    let projectName: String?
    let category: String

    init(_ draft: TodoDraft) {
        title = draft.title
        dueDate = PostListQuery.day(draft.dueAt)
        projectName = draft.projectName
        category = draft.linkKind.serverCategory
    }
}

/// PATCH /todos/{id} 요청
struct ServerTodoPatchRequestDTO: Codable, Equatable {
    /// 완료 · 미완료
    let status: String
}

extension TodoLinkKind {
    init(serverCategory: String?) {
        switch serverCategory {
        case "프로젝트 업무": self = .checklist
        case "결재": self = .approval
        case "일정": self = .schedule
        default: self = .manual
        }
    }

    var serverCategory: String {
        switch self {
        case .checklist: return "프로젝트 업무"
        case .approval: return "결재"
        case .schedule: return "일정"
        case .manual, .unknown: return "개인 업무"
        }
    }
}

extension TodoStatus {
    var serverValue: String { self == .done ? "완료" : "미완료" }
}
