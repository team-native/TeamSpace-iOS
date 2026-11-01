import Foundation

/// 알림 설정을 기기에 저장합니다. (민감 정보가 아니라 Keychain 이 아닌 UserDefaults 사용)
final class UserDefaultsNotificationSettingsRepository: NotificationSettingsRepository, @unchecked Sendable {
    static let storageKey = "notification.settings.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() async -> NotificationSettings {
        guard let data = defaults.data(forKey: Self.storageKey) else { return .default }
        do {
            return try JSONDecoder().decode(NotificationSettingsDTO.self, from: data).toEntity()
        } catch {
            // 저장 형식이 바뀌었으면 기본값으로 다시 시작
            AppLog.record(error, context: "notificationSettings.decode", logger: AppLog.push)
            return .default
        }
    }

    func save(_ settings: NotificationSettings) async throws {
        do {
            let data = try JSONEncoder().encode(NotificationSettingsDTO(settings))
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            throw AppError.unknown(String(describing: error))
        }
    }
}
