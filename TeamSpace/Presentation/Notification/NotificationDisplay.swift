import SwiftUI

/// 알림 센터 필터 (Figma 02-2: 전체 · 내 업무 · 재정 · 일정 · 공지)
enum NotificationFilter: Hashable, CaseIterable {
    case all
    case personalTask
    case finance
    case schedule
    case notice

    var title: String {
        switch self {
        case .all: return "전체"
        case .personalTask: return "내 업무"
        case .finance: return "재정"
        case .schedule: return "일정"
        case .notice: return "공지"
        }
    }

    func matches(_ notification: AppNotification) -> Bool {
        switch self {
        case .all: return true
        case .personalTask: return notification.type.category == .personalTask
        case .finance: return notification.type.category == .finance
        case .schedule: return notification.type.category == .schedule
        case .notice: return notification.type.category == .notice
        }
    }
}

/// 날짜 묶음 (오늘 / 이번 주 / 이전)
struct NotificationSection: Identifiable {
    let id: String
    let title: String
    let items: [AppNotification]
}

extension NotificationType {
    /// 카드 위 작은 출처 문구
    var sourceLabel: String {
        switch self {
        case .approval, .approvalResult: return "내 업무 · 결재"
        case .finance: return "NativeLab 재정"
        case .schedule: return "Native 일정"
        case .rule: return "제도 · 규칙 변경"
        case .notice: return "Native 전체 공지"
        case .unknown: return "알림"
        }
    }

    var icon: TSIcon {
        switch self {
        case .approval: return .clipboard
        case .approvalResult: return .checkCircle
        case .finance: return .creditCard
        case .schedule: return .calendar
        case .rule: return .bookOpen
        case .notice, .unknown: return .bell
        }
    }

    /// 안 읽은 알림의 아이콘 색 · 타일 배경
    var tint: Color {
        switch self {
        case .approval: return .tsPrimary
        case .finance: return .tsPositive
        default: return .tsInk2
        }
    }

    var tileBackground: Color {
        switch self {
        case .approval: return .tsPrimarySoft
        default: return .tsSurface2
        }
    }
}
