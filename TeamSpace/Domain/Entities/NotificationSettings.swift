import Foundation

/// 02-9 알림 설정에서 켜고 끄는 알림 종류
enum NotificationSettingCategory: String, CaseIterable, Hashable, Sendable {
    case personalTask   // 결재 · 내 할 일
    case finance        // 재정
    case rule           // 제도 · 규칙 변경
    case schedule       // 일정
    case notice         // 전체 공지
}

/// 방해 금지 시간 — 이 시간에는 소리 없이 받아요.
struct QuietHours: Equatable, Sendable {
    var isEnabled: Bool
    /// 0~23시
    var startHour: Int
    var endHour: Int

    static let `default` = QuietHours(isEnabled: true, startHour: 22, endHour: 8)

    func contains(hour: Int) -> Bool {
        guard isEnabled else { return false }
        if startHour == endHour { return false }
        if startHour < endHour {
            return hour >= startHour && hour < endHour
        }
        return hour >= startHour || hour < endHour
    }
}

/// 잠금 화면 미리보기
enum LockScreenPreview: String, CaseIterable, Sendable {
    case showContent    // 내용까지 보기
    case hideSensitive  // 민감한 내용 숨기기 (금액 · 결재 내용)
}

struct NotificationSettings: Equatable, Sendable {
    var enabledCategories: Set<NotificationSettingCategory>
    var quietHours: QuietHours
    var lockScreenPreview: LockScreenPreview

    /// 처음 설치하면 모든 알림을 켜 둡니다.
    static let `default` = NotificationSettings(
        enabledCategories: Set(NotificationSettingCategory.allCases),
        quietHours: .default,
        lockScreenPreview: .hideSensitive
    )

    func isEnabled(_ category: NotificationSettingCategory) -> Bool {
        enabledCategories.contains(category)
    }

    mutating func set(_ category: NotificationSettingCategory, isEnabled: Bool) {
        if isEnabled {
            enabledCategories.insert(category)
        } else {
            enabledCategories.remove(category)
        }
    }
}

/// 기기(iOS) 알림 권한 상태
enum NotificationPermissionStatus: Equatable, Sendable {
    /// 아직 묻지 않음 → 02-6 권한 안내
    case notDetermined
    /// 허용됨 (임시 허용 포함)
    case authorized
    /// 기기 설정에서 꺼짐 → 02-7 수신 진단
    case denied
}
