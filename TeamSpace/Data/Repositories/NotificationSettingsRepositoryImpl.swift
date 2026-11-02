import Foundation

/// 알림 설정 — 서버 `/me/notification-settings` 가 기준이고, 기기에는 마지막 값을 캐시해요.
/// 서버에 없는 규칙 알림 · 잠금 화면 미리보기는 기기에만 저장해요.
final class NotificationSettingsRepositoryImpl: NotificationSettingsRepository, @unchecked Sendable {
    private let client: APIClient
    private let cache: NotificationSettingsRepository

    init(client: APIClient, cache: NotificationSettingsRepository) {
        self.client = client
        self.cache = cache
    }

    /// 서버를 못 부르면 기기에 저장된 값을 보여줘요.
    func fetch() async -> NotificationSettings {
        let local = await cache.fetch()
        do {
            let server = try await client.request(
                Endpoint(method: .get, path: "me/notification-settings"),
                as: ServerNotificationSettingsDTO.self
            )
            let merged = server.merged(into: local)
            if merged != local { try? await cache.save(merged) }
            return merged
        } catch {
            AppLog.record(error, context: "notificationSettings.fetch", logger: AppLog.push)
            return local
        }
    }

    /// 서버에 먼저 저장하고, 성공하면 기기 캐시도 바꿔요.
    func save(_ settings: NotificationSettings) async throws {
        let endpoint = Endpoint(
            method: .patch,
            path: "me/notification-settings",
            body: ServerNotificationSettingsPatchDTO(settings)
        )
        do {
            _ = try await client.request(endpoint, as: ServerNotificationSettingsDTO.self)
        } catch NetworkError.emptyData {
            // 본문 없이 성공해도 괜찮아요.
        } catch let error as NetworkError {
            throw error.asAppError
        }
        try await cache.save(settings)
    }
}
