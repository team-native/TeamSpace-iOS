import SwiftUI

extension TodoLinkKind {
    /// 할 일 설명 끝에 붙는 업무 이름
    var title: String {
        switch self {
        case .checklist: return "프로젝트 업무"
        case .approval: return "받은 결재"
        case .schedule: return "일정"
        case .manual, .unknown: return "수동 할 일"
        }
    }

    /// 빠르게 추가에서 고를 수 있는 연결
    static let selectable: [TodoLinkKind] = [.manual, .checklist, .schedule]
}

extension TodoItem {
    var isDone: Bool { status == .done }

    func isDueToday(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.isDate(dueAt, inSameDayAs: now)
    }

    /// "오늘 18:00 · Book-on · 프로젝트 업무" / "10.23 15:00–16:00 · 온라인 · Book-on" / "10.16 09:30 완료 · Book-on · 수동 할 일"
    func metaText(now: Date = Date(), calendar: Calendar = .current) -> String {
        if isDone, let completedAt {
            let done = "\(TSFormat.shortDate(completedAt)) \(TSFormat.time(completedAt)) 완료"
            return [done, projectName, linkKind.title].compactMap { $0 }.joined(separator: " · ")
        }
        if linkKind == .schedule, let endsAt {
            let when = "\(TSFormat.shortDate(dueAt)) \(TSFormat.timeRange(dueAt, endsAt))"
            return [when, place, projectName].compactMap { $0 }.joined(separator: " · ")
        }
        let day = calendar.isDate(dueAt, inSameDayAs: now) ? "오늘" : TSFormat.shortDate(dueAt)
        let when = hasTime ? "\(day) \(TSFormat.time(dueAt))" : day
        return [when, projectName, linkKind.title].compactMap { $0 }.joined(separator: " · ")
    }

    /// "미완료" / "미완료 · 결재 대기" / "예정" / "완료"
    func badgeTitle(now: Date = Date(), calendar: Calendar = .current) -> String {
        if isDone { return "완료" }
        let isUpcoming = calendar.startOfDay(for: dueAt) > calendar.startOfDay(for: now)
        if isUpcoming { return "예정" }
        return linkKind == .approval ? "미완료 · 결재 대기" : "미완료"
    }

    /// 카드 아래 연결 링크 제목 (연결이 없으면 nil)
    var linkTitle: String? {
        switch linkKind {
        case .checklist: return "연결된 체크리스트 보기"
        case .approval: return "받은 결재 열기"
        case .schedule: return "연결된 일정 보기"
        case .manual, .unknown: return nil
        }
    }

    /// 연결 링크를 눌렀을 때 갈 화면
    var linkRoute: AppRoute? {
        switch linkKind {
        case .approval:
            return linkedId.map { .approvalDetail(documentId: $0) }
        case .checklist:
            return .comingSoon(title: "체크리스트")
        case .schedule:
            return .comingSoon(title: "일정 상세")
        case .manual, .unknown:
            return nil
        }
    }
}

/// 07-2 섹션 — 오늘 / 예정 · 날짜 / 완료 · 날짜
struct TodoSection: Identifiable, Equatable {
    enum Kind: CaseIterable {
        case today
        case upcoming
        case done

        var title: String {
            switch self {
            case .today: return "오늘"
            case .upcoming: return "예정"
            case .done: return "완료"
            }
        }
    }

    let kind: Kind
    let date: Date
    let items: [TodoItem]

    var id: String { "\(kind.title)-\(TSFormat.shortDate(date))" }

    /// "오늘 · 10.16"
    var title: String { "\(kind.title) · \(TSFormat.shortDate(date))" }
}
