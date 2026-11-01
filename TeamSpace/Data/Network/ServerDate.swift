import Foundation

/// 서버 날짜 읽기 — ISO8601 과 Python `isoformat()` 을 모두 받아요.
/// - `2026-11-02T03:12:45Z` · `2026-11-02T12:12:45+09:00`
/// - `2026-11-02T03:12:45.123456+00:00` (마이크로초)
/// - `2026-11-02T03:12:45.123456` (시간대 없음 → UTC 로 봐요)
enum ServerDate {
    static func parse(_ text: String) -> Date? {
        var value = text.trimmingCharacters(in: .whitespaces)
        if !hasTimeZone(value) { value += "Z" }
        value = trimmingFraction(value)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = value.contains(".")
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter.date(from: value)
    }

    /// 시각 뒤에 `Z` 나 `+09:00` · `-05:00` 이 있는지
    private static func hasTimeZone(_ value: String) -> Bool {
        guard let timeStart = value.firstIndex(of: "T") else { return true }
        let time = value[timeStart...]
        return time.hasSuffix("Z") || time.contains("+") || time.dropFirst().contains("-")
    }

    /// 소수점 아래는 3자리까지만 남겨요. (ISO8601DateFormatter 는 밀리초까지만 읽어요)
    private static func trimmingFraction(_ value: String) -> String {
        guard let dot = value.firstIndex(of: ".") else { return value }
        let fractionStart = value.index(after: dot)
        let fractionEnd = value[fractionStart...].firstIndex { !$0.isNumber } ?? value.endIndex
        let digits = value[fractionStart..<fractionEnd]
        let millis = String(digits.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
        return String(value[..<fractionStart]) + millis + String(value[fractionEnd...])
    }
}
