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
}
