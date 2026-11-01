import Foundation
import Observation

/// 02-9 알림 설정
@Observable
@MainActor
final class NotificationSettingsViewModel {
    private(set) var settings: NotificationSettings = .default
    private(set) var permission: NotificationPermissionStatus?
    var toastMessage: String?

    private let fetchSettingsUseCase: FetchNotificationSettingsUseCase
    private let updateSettingsUseCase: UpdateNotificationSettingsUseCase
    private let checkPermissionUseCase: CheckNotificationPermissionUseCase

    init(
        fetchSettingsUseCase: FetchNotificationSettingsUseCase,
        updateSettingsUseCase: UpdateNotificationSettingsUseCase,
        checkPermissionUseCase: CheckNotificationPermissionUseCase
    ) {
        self.fetchSettingsUseCase = fetchSettingsUseCase
        self.updateSettingsUseCase = updateSettingsUseCase
        self.checkPermissionUseCase = checkPermissionUseCase
    }

    let categories = NotificationSettingCategory.allCases

    /// 기기 알림이 꺼져 있으면 권한 안내(02-6) 또는 수신 진단(02-7) 으로 보냅니다.
    var permissionRoute: AppRoute? {
        switch permission {
        case .notDetermined: return .notificationPermission
        case .denied: return .notificationTroubleshoot
        case .authorized, .none: return nil
        }
    }

    var quietHoursDescription: String {
        "\(settings.quietHours.rangeText) 에는 소리 없이 받아요"
    }

    func load() async {
        settings = await fetchSettingsUseCase.execute()
        await refreshPermission()
    }

    /// 기기 설정에서 돌아왔을 때 다시 확인
    func refreshPermission() async {
        permission = await checkPermissionUseCase.execute()
    }

    func isEnabled(_ category: NotificationSettingCategory) -> Bool {
        settings.isEnabled(category)
    }

    func setEnabled(_ category: NotificationSettingCategory, isEnabled: Bool) async {
        var updated = settings
        updated.set(category, isEnabled: isEnabled)
        await save(updated)
    }

    func setQuietHours(isEnabled: Bool) async {
        var updated = settings
        updated.quietHours.isEnabled = isEnabled
        await save(updated)
    }

    /// 화면은 먼저 바꾸고, 저장에 실패하면 되돌립니다.
    private func save(_ updated: NotificationSettings) async {
        let previous = settings
        settings = updated
        do {
            try await updateSettingsUseCase.execute(updated)
        } catch {
            settings = previous
            AppLog.record(error, context: "saveNotificationSettings", logger: AppLog.push)
            toastMessage = "설정을 저장하지 못했어요. 다시 시도해 주세요."
        }
    }
}
