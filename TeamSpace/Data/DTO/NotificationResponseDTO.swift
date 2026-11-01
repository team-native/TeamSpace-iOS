import Foundation

/// GET /notifications 응답의 `data` — 서버(develop)는 `{ items, nextCursor }`, 예전 명세서 예시는 `{ list }`
struct NotificationListResponseDTO: Decodable {
    let items: [NotificationResponseDTO]
    let nextCursor: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([NotificationResponseDTO].self, forKey: .items)
            ?? container.decode([NotificationResponseDTO].self, forKey: .list)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case list
        case nextCursor
    }

    func toEntity() -> CursorPage<AppNotification> {
        CursorPage(items: items.map { $0.toEntity() }, nextCursor: nextCursor)
    }
}

struct NotificationResponseDTO: Decodable {
    let id: Int
    let type: NotificationType
    let title: String
    /// 명세서에 없는 필드 — 서버가 추가하면 사용
    let message: String?
    let deepLink: String?
    let isRead: Bool
    let createdAt: Date
    /// 명세서에 없는 필드 — 규칙 알림의 시행일
    let effectiveAt: Date?

    func toEntity() -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            title: title,
            message: message,
            deepLink: deepLink,
            isRead: isRead,
            createdAt: createdAt,
            effectiveAt: effectiveAt
        )
    }
}

/// PATCH /notifications/{id}/read 응답의 `data`
struct NotificationReadResponseDTO: Decodable {
    let success: Bool?
    let updatedId: Int?
}
