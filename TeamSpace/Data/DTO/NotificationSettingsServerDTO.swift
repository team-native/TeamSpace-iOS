import Foundation

/// GET · PATCH /me/notification-settings (TeamSpace-backend `account.py`)
/// `{ push, kinds: { "내 업무", "재정", "일정", "공지", "게시판" }, dnd, dndFrom: "23:00", dndTo: "08:00", dndDays: ["월", ...] }`
struct ServerNotificationSettingsDTO: Decodable {
    let kinds: [String: Bool]
    let dnd: Bool?
    let dndFrom: String?
    let dndTo: String?

    private enum CodingKeys: String, CodingKey { case kinds, dnd, dndFrom, dndTo }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kinds = (try? container.decodeIfPresent([String: Bool].self, forKey: .kinds)) ?? [:]
        dnd = try? container.decodeIfPresent(Bool.self, forKey: .dnd)
        dndFrom = try? container.decodeIfPresent(String.self, forKey: .dndFrom)
        dndTo = try? container.decodeIfPresent(String.self, forKey: .dndTo)
    }

    /// 서버 분류 이름 — 규칙(제도 변경)은 서버에 따로 없어 기기에만 저장해요.
    static func serverKind(_ category: NotificationSettingCategory) -> String? {
        switch category {
        case .personalTask: return "내 업무"
        case .finance: return "재정"
        case .schedule: return "일정"
        case .notice: return "공지"
        case .rule: return nil
        }
    }

    /// "23:00" → 23
    static func hour(_ text: String?) -> Int? {
        guard let text, let hour = Int(text.prefix { $0 != ":" }), (0...23).contains(hour) else { return nil }
        return hour
    }

    /// 서버 값으로 덮어쓰고, 서버에 없는 규칙 · 잠금 화면 미리보기는 기기 값을 그대로 둬요.
    func merged(into local: NotificationSettings) -> NotificationSettings {
        var settings = local
        for category in NotificationSettingCategory.allCases {
            guard let kind = Self.serverKind(category), let isOn = kinds[kind] else { continue }
            settings.set(category, isEnabled: isOn)
        }
        if let dnd { settings.quietHours.isEnabled = dnd }
        if let start = Self.hour(dndFrom) { settings.quietHours.startHour = start }
        if let end = Self.hour(dndTo) { settings.quietHours.endHour = end }
        return settings
    }
}

/// PATCH /me/notification-settings 요청 — 앱이 다루는 값만 보내요. (push · dndDays · 게시판은 건드리지 않음)
struct ServerNotificationSettingsPatchDTO: Encodable {
    let kinds: [String: Bool]
    let dnd: Bool
    let dndFrom: String
    let dndTo: String

    init(_ settings: NotificationSettings) {
        var kinds: [String: Bool] = [:]
        for category in NotificationSettingCategory.allCases {
            guard let kind = ServerNotificationSettingsDTO.serverKind(category) else { continue }
            kinds[kind] = settings.isEnabled(category)
        }
        self.kinds = kinds
        dnd = settings.quietHours.isEnabled
        dndFrom = String(format: "%02d:00", settings.quietHours.startHour)
        dndTo = String(format: "%02d:00", settings.quietHours.endHour)
    }
}
