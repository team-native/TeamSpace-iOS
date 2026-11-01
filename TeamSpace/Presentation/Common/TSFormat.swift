import Foundation

/// 화면 표시용 포맷
enum TSFormat {
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd HH:mm"
        return formatter
    }()

    /// 2026. 01. 27 22:58
    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// 방금 / 32분 전 / 2시간 전 / 3일 전 / 10.02
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return "방금"
        case ..<3_600: return "\(Int(seconds / 60))분 전"
        case ..<86_400: return "\(Int(seconds / 3_600))시간 전"
        case ..<(86_400 * 7): return "\(Int(seconds / 86_400))일 전"
        default: return monthDayFormatter.string(from: date)
        }
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM.dd"
        return formatter
    }()
}
