import Foundation

final class NotificationRepositoryImpl: NotificationRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchNotifications(page: Int, limit: Int) async throws -> [AppNotification] {
        let endpoint = Endpoint(
            method: .get,
            path: "notifications",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        do {
            return try await client.request(endpoint, as: NotificationListResponseDTO.self).list.map { $0.toEntity() }
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
