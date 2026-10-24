import Foundation

/// GET /notifications 응답의 `data`
struct NotificationListResponseDTO: Decodable {
    let list: [NotificationResponseDTO]
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

    func toEntity() -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            title: title,
            message: message,
            deepLink: deepLink,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}

/// PATCH /notifications/{id}/read 응답의 `data`
struct NotificationReadResponseDTO: Decodable {
    let success: Bool?
    let updatedId: Int?
}
