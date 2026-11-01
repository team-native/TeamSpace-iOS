import SwiftUI

extension ApplicationStatus: BadgeRepresentable {
    var badgeTitle: String {
        switch self {
        case .submitted: return "접수"
        case .reviewing: return "검토 중"
        case .accepted: return "참여 확정"
        case .declined: return "미선정"
        case .canceled: return "신청 취소"
        case .unknown: return "확인 중"
        }
    }

    var badgeTone: BadgeTone {
        switch self {
        case .reviewing: return .primary
        case .accepted: return .positive
        case .submitted, .declined, .canceled, .unknown: return .neutral
        }
    }
}

extension Availability {
    var title: String {
        switch self {
        case .tenHours: return "주 10시간"
        case .twentyHours: return "주 20시간"
        case .fullTime: return "풀타임"
        case .unknown: return "협의"
        }
    }
}

extension RecruitmentPost {
    /// "iOS · 1명"
    var roleBadgeText: String { "\(opening.role) · \(opening.headcount)명" }

    /// "2026.10.12–10.25"
    var recruitPeriodText: String {
        "\(TSFormat.fullDate(recruitStart))–\(TSFormat.shortDate(recruitEnd))"
    }

    /// 이미 참여 중이거나 신청했으면 신청할 수 없어요.
    var canApply: Bool { !isJoined && myApplicationStatus == nil }

    /// 아래 버튼 문구
    var applyButtonTitle: String {
        if isJoined { return "이미 참여 중인 프로젝트예요" }
        if let status = myApplicationStatus { return "신청 완료 · \(status.badgeTitle)" }
        return "\(projectName) 참여 신청하기"
    }
}

extension ProjectApplication {
    /// "토벌 보수 앱 · iOS 개발"
    var titleText: String { "\(projectName) · \(role)" }

    /// "10.15 신청 · NativeOps"
    var compactMeta: String { "\(TSFormat.shortDate(appliedAt)) 신청 · \(department)" }

    /// 접은 카드 설명
    var compactDescription: String {
        switch status {
        case .submitted: return "검토 전 · 모집 마감 전까지 수정·취소 가능"
        case .reviewing: return "PM 검토 중 · 결과 확정 전까지 취소 가능"
        case .accepted:
            let when = decidedAt.map { "\(TSFormat.shortDate($0)) 확정" } ?? "참여 확정"
            return "\(when) · 참여 프로젝트에서 일정 확인"
        case .declined:
            let when = decidedAt.map { "\(TSFormat.shortDate($0)) 결과" } ?? "결과"
            return "\(when) · \(resultReason ?? "아쉽지만 이번에는 함께하지 못해요.")"
        case .canceled, .unknown:
            return "신청을 취소했어요."
        }
    }

    /// (단계, 설명, 지나왔는지) — 신청 접수 → PM 검토 → 결과
    var progressSteps: [(title: String, detail: String, isDone: Bool)] {
        let submitted = "\(TSFormat.shortDate(appliedAt)) \(TSFormat.time(appliedAt)) · 제출 완료"
        let review = reviewedAt.map { "\(TSFormat.shortDate($0)) \(TSFormat.time($0)) · \(pmName) 확인" } ?? "PM 확인 전"
        let result: String
        if let decidedAt {
            result = "\(TSFormat.shortDate(decidedAt)) · \(status.badgeTitle)"
        } else {
            result = resultDueDate.map { "\(TSFormat.shortDate($0))까지 개인 업무 알림으로 안내" } ?? "개인 업무 알림으로 안내"
        }
        return [
            ("신청 접수", submitted, true),
            (status == .submitted ? "PM 검토 전" : "PM 검토 중", review, status != .submitted),
            (decidedAt == nil ? "결과 안내 예정" : "결과 안내", result, decidedAt != nil)
        ]
    }
}

extension Applicant {
    /// "10.14 09:10 신청 · 주 10시간 가능"
    var metaText: String {
        "\(TSFormat.shortDate(appliedAt)) \(TSFormat.time(appliedAt)) 신청 · \(availability.title) 가능"
    }
}

/// 08-6 · 08-7 상태 칩 (nil = 전체)
enum ApplicationFilter: Hashable, CaseIterable {
    case all
    case submitted
    case reviewing
    case accepted
    case declined

    var status: ApplicationStatus? {
        switch self {
        case .all: return nil
        case .submitted: return .submitted
        case .reviewing: return .reviewing
        case .accepted: return .accepted
        case .declined: return .declined
        }
    }

    var title: String { status?.badgeTitle ?? "전체" }
}
