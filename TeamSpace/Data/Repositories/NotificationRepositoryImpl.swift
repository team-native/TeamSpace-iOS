import Foundation

final class NotificationRepositoryImpl: NotificationRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchNotifications(cursor: String?, limit: Int) async throws -> CursorPage<AppNotification> {
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        let endpoint = Endpoint(method: .get, path: "notifications", queryItems: queryItems)
        do {
            return try await client.request(endpoint, as: NotificationListResponseDTO.self).toEntity()
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    func markAsRead(id: Int) async throws {
        let endpoint = Endpoint(method: .patch, path: "notifications/\(id)/read")
        do {
            _ = try await client.request(endpoint, as: NotificationReadResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
