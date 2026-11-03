import Foundation

/// 모집 자리 한 개 입력 [Admin] — PATCH /admin/projects/{id} 의 openings 한 항목
struct OpeningDraft: Equatable, Identifiable, Sendable {
    static let descriptionLimit = 120
    static let headcountRange = 1...10

    let id: UUID
    /// 직군 (예: "iOS") — 목록 직군 필터 · 참여 신청의 position 이 돼요.
    var role = ""
    /// 자리 이름 (예: "iOS 개발")
    var title = ""
    var headcount = 1
    var startDate: Date
    var endDate: Date
    var description = ""

    /// 오늘부터 2주 모집으로 시작해요.
    init(now: Date = Date(), calendar: Calendar = .current) {
        id = UUID()
        let today = calendar.startOfDay(for: now)
        startDate = today
        endDate = calendar.date(byAdding: .day, value: 14, to: today) ?? today
    }

    /// 지금 자리로 채워요. 설명 앞의 기간("11.01 – 11.15")은 빼요.
    init(editing opening: ProjectOpening, now: Date = Date(), calendar: Calendar = .current) {
        self.init(now: now, calendar: calendar)
        role = opening.role
        title = opening.title == opening.role ? "" : opening.title
        headcount = min(max(opening.headcount, Self.headcountRange.lowerBound), Self.headcountRange.upperBound)
        if let start = opening.startDate { startDate = start }
        if let end = opening.endDate { endDate = end }
        description = opening.description
            .components(separatedBy: " · ")
            .filter { !$0.contains("–") }
            .joined(separator: " · ")
    }

    /// 자리 이름을 비우면 직군으로 보여줘요.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? role.trimmingCharacters(in: .whitespaces) : trimmed
    }
}
