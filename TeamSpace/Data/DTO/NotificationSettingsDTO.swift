import Foundation

/// 기기(UserDefaults)에 저장하는 알림 설정 형태.
/// 서버 설정 API 가 생기면 같은 DTO 를 요청/응답에 맞춰 고쳐 쓰면 됩니다.
struct NotificationSettingsDTO: Codable {
    let enabledCategories: [String]
    let quietHoursEnabled: Bool
    let quietHoursStart: Int
    let quietHoursEnd: Int
    let lockScreenPreview: String

    init(_ settings: NotificationSettings) {
        enabledCategories = NotificationSettingCategory.allCases
            .filter { settings.isEnabled($0) }
            .map(\.rawValue)
        quietHoursEnabled = settings.quietHours.isEnabled
        quietHoursStart = settings.quietHours.startHour
        quietHoursEnd = settings.quietHours.endHour
        lockScreenPreview = settings.lockScreenPreview.rawValue
    }

    func toEntity() -> NotificationSettings {
        NotificationSettings(
            enabledCategories: Set(enabledCategories.compactMap(NotificationSettingCategory.init(rawValue:))),
            quietHours: QuietHours(isEnabled: quietHoursEnabled, startHour: quietHoursStart, endHour: quietHoursEnd),
            lockScreenPreview: LockScreenPreview(rawValue: lockScreenPreview) ?? NotificationSettings.default.lockScreenPreview
        )
    }
}
