import SwiftUI

/// 알림 센터 필터 (Figma 02-2: 전체 · 내 업무 · 재정 · 일정 · 공지)
enum NotificationFilter: Hashable, CaseIterable {
    case all
    case personalTask
    case finance
    case schedule
    case rule
    case notice

    var title: String {
        switch self {
        case .all: return "전체"
        case .personalTask: return "내 업무"
        case .finance: return "재정"
        case .schedule: return "일정"
        case .rule: return "규칙"
        case .notice: return "공지"
        }
    }

    func matches(_ notification: AppNotification) -> Bool {
        switch self {
        case .all: return true
        case .personalTask: return notification.type.category == .personalTask
        case .finance: return notification.type.category == .finance
        case .schedule: return notification.type.category == .schedule
        case .rule: return notification.type.category == .rule
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
        case .inquiryAnswer: return "내 문의 · 답변"
        case .unknown: return "알림"
        }
    }

    /// 알림을 눌렀을 때 이동할 화면 이름 (해당 화면을 만들기 전까지 준비 중 화면)
    /// "자세히 보기"로 이동할 화면. 규칙은 09-1, 일정은 07-7로 가고 나머지는 준비 중이에요.
    var targetRoute: AppRoute {
        switch self {
        case .rule: return .rules
        case .schedule: return .workspaceSchedules
        default: return .comingSoon(title: targetTitle)
        }
    }

    var targetTitle: String {
        switch self {
        case .approval, .approvalResult: return "결재"
        case .finance: return "재무"
        case .schedule: return "일정"
        case .rule: return "규칙 개정 비교"
        case .notice: return "공지"
        case .inquiryAnswer: return "내 문의"
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
        case .inquiryAnswer: return .megaphone
        case .notice, .unknown: return .bell
        }
    }

    /// 안 읽은 알림의 아이콘 색 · 타일 배경
    var tint: Color {
        switch self {
        case .approval, .inquiryAnswer: return .tsPrimary
        case .finance: return .tsPositive
        default: return .tsInk2
        }
    }

    var tileBackground: Color {
        switch self {
        case .approval, .inquiryAnswer: return .tsPrimarySoft
        default: return .tsSurface2
        }
    }
}
