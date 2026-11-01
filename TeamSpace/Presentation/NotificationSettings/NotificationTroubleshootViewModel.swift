import Foundation
import Observation

/// 02-7 알림 수신 진단 — 항목 하나
struct NotificationDiagnosis: Identifiable, Equatable {
    enum Level: Equatable {
        case ok
        case check
        case problem
    }

    let id: String
    let title: String
    let value: String
    let level: Level
}

/// 02-7 알림 수신 진단
@Observable
@MainActor
final class NotificationTroubleshootViewModel {
    private(set) var permission: NotificationPermissionStatus?
    private(set) var settings: NotificationSettings = .default
    /// "다시 확인" 을 눌렀는데도 아직 꺼져 있을 때 안내
    private(set) var recheckMessage: String?

    private let fetchSettingsUseCase: FetchNotificationSettingsUseCase
    private let checkPermissionUseCase: CheckNotificationPermissionUseCase

    init(
        fetchSettingsUseCase: FetchNotificationSettingsUseCase,
        checkPermissionUseCase: CheckNotificationPermissionUseCase
    ) {
        self.fetchSettingsUseCase = fetchSettingsUseCase
        self.checkPermissionUseCase = checkPermissionUseCase
    }

    var isResolved: Bool {
        permission == .authorized
    }

    var diagnoses: [NotificationDiagnosis] {
        let enabledCount = settings.enabledCategories.count
        let totalCount = NotificationSettingCategory.allCases.count
        return [
            NotificationDiagnosis(
                id: "permission",
                title: "iOS 알림 권한",
                value: isResolved ? "켜짐" : "꺼짐",
                level: isResolved ? .ok : .problem
            ),
            NotificationDiagnosis(id: "focus", title: "집중 모드", value: "기기에서 확인", level: .check),
            NotificationDiagnosis(
                id: "categories",
                title: "앱 알림 종류",
                value: "\(enabledCount)/\(totalCount)개 켜짐",
                level: enabledCount == 0 ? .problem : .ok
            ),
            NotificationDiagnosis(
                id: "notice",
                title: "전체 공지",
                value: settings.isEnabled(.notice) ? "켜짐" : "꺼짐",
                level: settings.isEnabled(.notice) ? .ok : .check
            )
        ]
    }

    func load() async {
        settings = await fetchSettingsUseCase.execute()
        permission = await checkPermissionUseCase.execute()
    }

    func recheck() async {
        await load()
        recheckMessage = isResolved ? nil : "아직 알림이 꺼져 있어요. 기기 설정에서 '알림 허용'을 켜 주세요."
    }
}
