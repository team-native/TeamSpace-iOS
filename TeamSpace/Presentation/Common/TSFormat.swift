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

    // MARK: 금액

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 3,560,000
    static func number(_ value: Int) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// 3,560,000원
    static func won(_ value: Int) -> String {
        number(value) + "원"
    }

    /// +7,260,000원 / -3,480,000원
    static func signedWon(_ value: Int) -> String {
        (value > 0 ? "+" : value < 0 ? "-" : "") + won(abs(value))
    }

    /// +12.8% / -3.1%
    static func signedPercent(_ value: Double) -> String {
        (value >= 0 ? "+" : "-") + String(format: "%.1f%%", abs(value))
    }

    // MARK: 날짜

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter
    }

    private static let monthDayKoreanFormatter = formatter("M월 d일")
    private static let yearMonthFormatter = formatter("yyyy년 M월")
    private static let monthFormatter = formatter("M월")
    private static let dayFormatter = formatter("dd")
    private static let weekdayFormatter = formatter("EEEE")
    private static let shortWeekdayFormatter = formatter("E")
    private static let shortDateFormatter = formatter("MM.dd")
    private static let fullDateFormatter = formatter("yyyy.MM.dd")
    private static let longDateFormatter = formatter("yyyy년 M월 d일")
    private static let timeFormatter = formatter("HH:mm")

    /// 10월 21일
    static func monthDay(_ date: Date) -> String {
        monthDayKoreanFormatter.string(from: date)
    }

    /// 2026년 10월
    static func yearMonth(_ date: Date) -> String {
        yearMonthFormatter.string(from: date)
    }

    /// 10월
    static func month(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    /// 26
    static func day(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// 10.18
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// 2026.10.18
    static func fullDate(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }

    /// 2026년 10월 16일
    static func longDate(_ date: Date) -> String {
        longDateFormatter.string(from: date)
    }

    /// 15:00
    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// 15:00–16:00
    static func timeRange(_ start: Date, _ end: Date) -> String {
        "\(time(start))–\(time(end))"
    }

    /// 월
    static func shortWeekday(_ date: Date) -> String {
        shortWeekdayFormatter.string(from: date)
    }

    /// 월요일
    static func weekday(_ date: Date) -> String {
        weekdayFormatter.string(from: date)
    }

    /// D-27 / D-Day / D+3
    static func dDay(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days == 0 { return "D-Day" }
        return days > 0 ? "D-\(days)" : "D+\(-days)"
    }

    /// 오늘 업데이트 / 어제 업데이트 / 3일 전 / 10월 10일
    static func updated(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        switch days {
        case ..<1: return "오늘 업데이트"
        case 1: return "어제 업데이트"
        case 2..<7: return "\(days)일 전"
        default: return monthDay(date)
        }
    }
}
