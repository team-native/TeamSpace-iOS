import SwiftUI

/// 02-9 알림 종류 행 — Figma 문구 · 아이콘 · 타일 색
extension NotificationSettingCategory {
    var title: String {
        switch self {
        case .personalTask: return "결재 · 내 할 일"
        case .finance: return "재정"
        case .rule: return "제도 · 규칙 변경"
        case .schedule: return "일정"
        case .notice: return "전체 공지"
        }
    }

    var detail: String {
        switch self {
        case .personalTask: return "결재 요청 · 반려 · 내 차례가 된 일"
        case .finance: return "지출 승인 · 정산 · 예산 변동"
        case .rule: return "회칙 · 운영 규칙이 바뀌었을 때"
        case .schedule: return "회의 · 행사 하루 전과 1시간 전"
        case .notice: return "운영진이 보내는 전체 공지"
        }
    }

    var icon: TSIcon {
        switch self {
        case .personalTask: return .clipboardCheck
        case .finance: return .wallet
        case .rule: return .bookOpen
        case .schedule: return .calendar
        case .notice: return .megaphone
        }
    }

    var tint: Color {
        switch self {
        case .personalTask: return .tsPrimary
        case .finance: return .tsApricot
        case .rule: return .tsPositive
        case .schedule: return .tsViolet
        case .notice: return .tsInk3
        }
    }

    var tileBackground: Color {
        switch self {
        case .personalTask: return .tsPrimarySoft
        case .finance: return .tsApricotSoft
        case .rule: return .tsPositiveSoft
        case .schedule: return .tsVioletSoft
        case .notice: return .tsSurface2
        }
    }
}

extension LockScreenPreview {
    var title: String {
        switch self {
        case .showContent: return "내용까지 보기"
        case .hideSensitive: return "민감한 내용 숨기기"
        }
    }

    var detail: String {
        switch self {
        case .showContent: return "잠금 화면에서도 알림 내용을 모두 보여줘요."
        case .hideSensitive: return "금액 · 결재 내용은 앱을 열어야 보여요."
        }
    }
}

extension QuietHours {
    /// 예) "22:00 – 08:00"
    var rangeText: String {
        String(format: "%02d:00 – %02d:00", startHour, endHour)
    }
}
