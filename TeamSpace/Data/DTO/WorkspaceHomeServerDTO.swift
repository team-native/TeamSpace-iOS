import Foundation

/// GET /me/summary — 내 공간 숫자 요약 (TeamSpace-backend develop `space.my_summary`)
struct ServerMeSummaryDTO: Decodable {
    struct Todos: Decodable {
        let today: Int
        let completed: Int
    }

    let unreadNotifications: Int
    let submittedApprovals: Int
    let myPosts: Int
    let myProposals: Int
    let myInquiries: Int
    let receivedApprovals: Int
    let todos: Todos
}

/// GET /notifications?unread=true 의 한 항목 — `{id, kind, title, createdAt, href, unread}`
struct ServerNotificationPreviewDTO: Decodable {
    let kind: String
    let title: String
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = (try? container.decodeIfPresent(String.self, forKey: .kind)) ?? ""
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt)).flatMap { $0.flatMap(ServerDate.parse) }
    }

    private enum CodingKeys: String, CodingKey { case kind, title, createdAt }
}

extension ServerEventDTO {
    /// 07-1 홈 예정 일정
    func toWorkspaceSchedule() -> WorkspaceSchedule? {
        guard let event = toEntity() else { return nil }
        let place = [event.place, event.placeDetail ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
        return WorkspaceSchedule(
            id: event.id, scope: event.scope, title: event.title, startsAt: event.startsAt, endsAt: event.endsAt,
            place: place, note: event.organizerName.isEmpty ? nil : event.organizerName
        )
    }
}
