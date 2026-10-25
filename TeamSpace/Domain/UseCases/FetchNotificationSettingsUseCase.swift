import Foundation

struct FetchNotificationSettingsUseCase {
    private let settingsRepository: NotificationSettingsRepository

    init(settingsRepository: NotificationSettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func execute() async -> NotificationSettings {
        await settingsRepository.fetch()
    }
}
