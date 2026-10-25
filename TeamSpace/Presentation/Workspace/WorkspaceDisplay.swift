import SwiftUI

extension AuthUser {
    /// 07-1 프로필 카드 아래 한 줄 — 내 역할과 추가 권한
    var workspaceRoleSummary: String {
        let roles = Set(roles)
        if roles.contains(.admin) { return "관리자 · 전체 운영 권한" }
        if roles.contains(.leader) { return "Leader · 운영 · 결재 권한" }
        if roles.contains(.fa) { return "FA · 재무 상세 열람 권한" }
        if roles.contains(.pm) { return "PM · 프로젝트 관리 · 결재 권한" }
        return "일반 사용자 · 추가 운영 권한 없음"
    }
}

extension WorkspaceApprovalPreview {
    /// "이시우 요청 · 10.16 · 현재 검토자 나"
    var metaText: String {
        "\(requesterName) 요청 · \(TSFormat.shortDate(requestedAt)) · 현재 검토자 나"
    }
}

extension WorkspaceSubmittedDocument {
    /// "이시우 검토 중" / "승인"
    var statusText: String {
        if status.isWaiting, let currentApproverName {
            return "\(currentApproverName) 검토 중"
        }
        return status.badgeTitle
    }

    /// "420,000원 · 10.14 제출 · 이시우 검토 중"
    var metaText: String {
        let parts = [amount.map(TSFormat.won), "\(TSFormat.shortDate(submittedAt)) 제출", statusText]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }
}

extension WorkspaceProject {
    /// "PM 이시우 · NativeLab · 6명"
    var metaText: String {
        "PM \(pmName) · \(team) · \(memberCount)명"
    }
}

extension WorkspaceScheduleScope {
    var title: String {
        switch self {
        case .personal: return "개인 업무"
        case .team: return "Native 일정"
        case .unknown: return "일정"
        }
    }

    var badgeTone: BadgeTone {
        self == .team ? .violet : .primary
    }
}

extension WorkspaceSchedule {
    /// "10.23 · 개인 업무"
    var badgeText: String {
        "\(TSFormat.shortDate(startsAt)) · \(scope.title)"
    }

    /// "15:00–16:00 · 온라인 · 변경자 이시우"
    var metaText: String {
        [TSFormat.timeRange(startsAt, endsAt), place, note].compactMap { $0 }.joined(separator: " · ")
    }
}

extension ProposalStatus {
    var title: String {
        switch self {
        case .reviewing: return "검토 중"
        case .adopted: return "채택"
        case .closed: return "종료"
        case .unknown: return "확인 중"
        }
    }
}

extension InquiryStatus {
    var title: String {
        switch self {
        case .reviewing: return "검토 중"
        case .answered: return "답변 완료"
        case .rejected: return "반려"
        case .unknown: return "확인 중"
        }
    }
}

extension WorkspaceRecords {
    /// 제목이 길면 앞부분만 보여주는 글자 수
    static let previewTitleLimit = 14

    static func shortened(_ title: String) -> String {
        title.count > previewTitleLimit ? String(title.prefix(previewTitleLimit)) + "…" : title
    }

    /// "이번 주 함께 읽을 책 추천해요 · 10.15"
    var postText: String {
        guard let latestPost else { return "아직 남긴 글이 없어요." }
        return "\(latestPost.title) · \(TSFormat.shortDate(latestPost.createdAt))"
    }

    /// "회의실 예약 현황을 한눈에… · 검토 중 · 추천 32"
    var proposalText: String {
        guard let latestProposal else { return "아직 작성한 제안이 없어요." }
        return "\(Self.shortened(latestProposal.title)) · \(latestProposal.status.title) · 추천 \(latestProposal.recommendCount)"
    }

    /// "회의실 예약 기준 · 답변 완료 / 안내 자료 · 검토 중"
    var inquiryText: String {
        guard !inquiries.isEmpty else { return "아직 남긴 문의가 없어요." }
        return inquiries.map { "\($0.title) · \($0.status.title)" }.joined(separator: " / ")
    }
}
