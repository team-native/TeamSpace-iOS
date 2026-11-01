import Foundation

extension InquiryStatus: BadgeRepresentable {
    var badgeTitle: String { title }

    var badgeTone: BadgeTone {
        switch self {
        case .received: return .neutral
        case .reviewing: return .primary
        case .answered: return .positive
        case .rejected: return .negative
        case .unknown: return .neutral
        }
    }

    /// 11-1 처리 흐름 (반려는 답변 완료 대신 끝나는 단계)
    static let flow: [InquiryStatus] = [.received, .reviewing, .answered, .rejected]
}

extension InquiryDepartment {
    var title: String {
        switch self {
        case .leader: return "Leader"
        case .nativeOps: return "NativeOps"
        case .pmo: return "PMO"
        case .fa: return "FA"
        case .unknown: return "담당 부서"
        }
    }

    /// 11-2 "NativeOps · 팀 운영 및 업무 환경"
    var scopeText: String {
        let scope: String
        switch self {
        case .leader: scope = "팀 방향과 주요 의사결정"
        case .nativeOps: scope = "팀 운영 및 업무 환경"
        case .pmo: scope = "프로젝트 운영과 일정"
        case .fa: scope = "재정 · 정산 · 계약"
        case .unknown: scope = "담당 부서 확인 필요"
        }
        return "\(title) · \(scope)"
    }
}

/// 11-1 상태 칩 — 전체 · 접수 · 검토 중 · 답변 완료 · 반려
enum InquiryFilter: Hashable {
    case all
    case status(InquiryStatus)

    static let allCases: [InquiryFilter] = [.all] + InquiryStatus.flow.map { InquiryFilter.status($0) }

    var title: String {
        switch self {
        case .all: return "전체"
        case .status(let status): return status.title
        }
    }

    func matches(_ inquiry: InquirySummary) -> Bool {
        switch self {
        case .all: return true
        case .status(let status): return inquiry.status == status
        }
    }
}

extension InquirySummary {
    /// "NativeOps · 10.05 · 익명"
    var metaText: String {
        "\(department.title) · \(TSFormat.shortDate(createdAt)) · \(isAnonymous ? "익명" : "실명")"
    }

    /// 11-4 "NativeOps · 2026.10.05 접수 · 익명"
    var detailMetaText: String {
        "\(department.title) · \(TSFormat.fullDate(createdAt)) 접수 · \(isAnonymous ? "익명" : "실명")"
    }

    /// 11-1 카드 아래 — "NativeOps 답변 · 10.08" / "NativeOps 반려 · 10.08"
    var replyTitle: String? {
        guard let reply = reply else { return nil }
        let kind = status == .rejected ? "반려" : "답변"
        return "\(reply.department.title) \(kind) · \(TSFormat.shortDate(reply.repliedAt))"
    }
}

extension InquiryHistory {
    /// "10.05 15:30 · NativeOps에 전달"
    var detailText: String {
        "\(TSFormat.shortDate(occurredAt)) \(TSFormat.time(occurredAt)) · \(note)"
    }
}

extension InquiryReference {
    /// "운영 규칙 · 본문 제공" / "공지"
    var caption: String {
        switch kind {
        case .rule: return "운영 규칙 · 본문 제공"
        case .notice: return "공지"
        case .unknown: return "참고 자료"
        }
    }

    var linkTitle: String { kind == .rule ? "관련 규칙 읽기" : "공지 보기" }

    var route: AppRoute {
        switch (kind, id) {
        case (.rule, .some(let id)): return .ruleDetail(id: id)
        case (.rule, .none): return .rules
        case (.notice, .some(let id)): return .noticeDetail(id: id)
        default: return .notices
        }
    }
}

/// 11-2로 들어올 때 미리 채우는 값 (후속 문의 · 권한 문의)
struct InquiryComposeContext: Hashable {
    var department: InquiryDepartment?
    var title: String?
    var followUpOf: Int?

    static let blank = InquiryComposeContext()

    /// 11-4 "이 답변에 후속 문의하기" · 11-7 "다시 문의하기"
    static func followUp(_ inquiry: InquirySummary) -> InquiryComposeContext {
        InquiryComposeContext(department: inquiry.department, title: "[후속] \(inquiry.title)", followUpOf: inquiry.id)
    }
}
