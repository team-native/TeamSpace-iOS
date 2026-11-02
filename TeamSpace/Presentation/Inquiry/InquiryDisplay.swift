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
        case (.notice, .some(let id)): return Int(id).map { .noticeDetail(id: $0) } ?? .notices
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

    /// 14-5 접근 불가 "NativeOps에 권한 문의"
    static let accessRequest = InquiryComposeContext(department: .nativeOps, title: "[권한 문의] ACCESS-403")

    /// 11-4 "이 답변에 후속 문의하기"는 같은 문의에 추가 메시지로, 11-7 "다시 문의하기"는 새 문의로 보내요.
    static func followUp(_ inquiry: InquirySummary) -> InquiryComposeContext {
        InquiryComposeContext(
            department: inquiry.department,
            title: "[후속] \(inquiry.title)",
            followUpOf: inquiry.status == .answered ? inquiry.id : nil
        )
    }
}

extension InquiryInboxItem {
    /// 11-5 "10.05 접수 · 익명 · NativeOps"
    var metaText: String {
        "\(TSFormat.shortDate(inquiry.createdAt)) 접수 · \(inquiry.isAnonymous ? "익명" : "실명") · \(inquiry.department.title)"
    }

    /// 11-5 "담당 양지우 · 10.08 공식 답변 등록" / "담당 미배정 · 확인 및 담당 배정 필요"
    var assigneeText: String {
        guard let assignee = assignee else { return "담당 미배정 · 확인 및 담당 배정 필요" }
        guard let last = history.last(where: { $0.status != .received }) else { return "담당 \(assignee)" }
        return "담당 \(assignee) · \(TSFormat.shortDate(last.occurredAt)) \(last.note)"
    }

    /// 11-5 카드 아래 링크
    var actionTitle: String {
        switch inquiry.status {
        case .received: return assignee == nil ? "문의 확인 · 담당 배정" : "검토 · 공식 답변 작성"
        case .reviewing: return "검토 · 공식 답변 작성"
        default: return "문의와 처리 이력 보기"
        }
    }

    /// 11-6 "익명 · 신원 표시 안 함" / "실명 · 이시우"
    var authorText: String {
        authorName.map { "실명 · \($0)" } ?? "익명 · 신원 표시 안 함"
    }

    /// 11-6 "2026.10.13 16:20 접수 · NativeOps"
    var receivedText: String {
        "\(TSFormat.fullDate(inquiry.createdAt)) \(TSFormat.time(inquiry.createdAt)) 접수 · \(inquiry.department.title)"
    }

    func matches(_ query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return true }
        return inquiry.title.localizedCaseInsensitiveContains(keyword) || inquiry.body.localizedCaseInsensitiveContains(keyword)
    }
}

/// 11-5 최근 처리 이력 한 줄
struct InquiryInboxLog: Equatable, Identifiable {
    let title: String
    let occurredAt: Date
    let actor: String
    let from: InquiryStatus
    let to: InquiryStatus

    var id: String { "\(title)-\(occurredAt.timeIntervalSince1970)" }

    /// "10.14 10:00 · 양지우 · 접수 → 검토 중"
    var detailText: String {
        "\(TSFormat.shortDate(occurredAt)) \(TSFormat.time(occurredAt)) · \(actor) · \(from.title) → \(to.title)"
    }
}

extension InquiryReplyDraft.Kind {
    var title: String { self == .answer ? "공식 답변" : "반려" }
    var resultStatus: InquiryStatus { self == .answer ? .answered : .rejected }
}
