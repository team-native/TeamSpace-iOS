import Foundation

struct UpdateNotificationSettingsUseCase {
    private let settingsRepository: NotificationSettingsRepository

    init(settingsRepository: NotificationSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute(_ settings: NotificationSettings) async throws {
        try await settingsRepository.save(settings)
    }
}
