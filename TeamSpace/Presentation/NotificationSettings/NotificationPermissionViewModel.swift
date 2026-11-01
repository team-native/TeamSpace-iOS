import Foundation
import Observation

/// 02-6 알림 권한 안내
@Observable
@MainActor
final class NotificationPermissionViewModel {
    private(set) var lockScreenPreview: LockScreenPreview = NotificationSettings.default.lockScreenPreview
    private(set) var isRequesting = false
    var errorMessage: String?

    private let fetchSettingsUseCase: FetchNotificationSettingsUseCase
    private let updateSettingsUseCase: UpdateNotificationSettingsUseCase
    private let requestPermissionUseCase: RequestNotificationPermissionUseCase

    init(
        fetchSettingsUseCase: FetchNotificationSettingsUseCase,
        updateSettingsUseCase: UpdateNotificationSettingsUseCase,
        requestPermissionUseCase: RequestNotificationPermissionUseCase
    ) {
        self.fetchSettingsUseCase = fetchSettingsUseCase
        self.updateSettingsUseCase = updateSettingsUseCase
        self.requestPermissionUseCase = requestPermissionUseCase
    }

    let previewOptions = LockScreenPreview.allCases

    func load() async {
        lockScreenPreview = await fetchSettingsUseCase.execute().lockScreenPreview
    }

    func select(_ preview: LockScreenPreview) async {
        let previous = lockScreenPreview
        lockScreenPreview = preview
        var settings = await fetchSettingsUseCase.execute()
        settings.lockScreenPreview = preview
        do {
            try await updateSettingsUseCase.execute(settings)
        } catch {
            lockScreenPreview = previous
            AppLog.record(error, context: "saveLockScreenPreview", logger: AppLog.push)
            errorMessage = "설정을 저장하지 못했어요. 다시 시도해 주세요."
        }
    }

    /// 시스템 권한 팝업 → 결과를 돌려줍니다. (허용: 이전 화면으로 / 거부: 02-7 수신 진단)
    func requestPermission() async -> NotificationPermissionStatus? {
        guard !isRequesting else { return nil }
        isRequesting = true
        defer { isRequesting = false }
        do {
            return try await requestPermissionUseCase.execute()
        } catch {
            AppLog.record(error, context: "requestNotificationPermission", logger: AppLog.push)
            errorMessage = "알림 권한을 요청하지 못했어요. 잠시 후 다시 시도해 주세요."
            return nil
        }
    }
}
