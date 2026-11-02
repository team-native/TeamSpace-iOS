import Foundation

/// 11 문의 대상 부서
enum InquiryDepartment: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case leader = "LEADER"
    case nativeOps = "NATIVE_OPS"
    case pmo = "PMO"
    case fa = "FA"
    case unknown = "UNKNOWN"

    static let unknownCase: InquiryDepartment = .unknown
    static let selectable: [InquiryDepartment] = [.leader, .nativeOps, .pmo, .fa]
}

extension InquiryStatus {
    /// 접수 · 검토 중 — 아직 답변 · 반려 전
    var isOpen: Bool { self == .received || self == .reviewing }
}

/// 11-1 내 문의 한 건
struct InquirySummary: Equatable, Identifiable, Sendable {
    let id: Int
    let department: InquiryDepartment
    let title: String
    let body: String
    let isAnonymous: Bool
    let createdAt: Date
    let status: InquiryStatus
    /// 답변 · 반려 사유 (없으면 nil)
    let reply: InquiryReply?
}

/// 공식 답변 또는 반려 사유
struct InquiryReply: Equatable, Sendable {
    let department: InquiryDepartment
    let body: String
    let repliedAt: Date
}

/// 11-4 처리 이력 한 줄 — "검토 중 · 10.06 10:20 · 예약 현황과 운영 기준 확인"
struct InquiryHistory: Equatable, Sendable {
    let status: InquiryStatus
    let occurredAt: Date
    let note: String
    /// 처리한 담당자 (11-5 최근 처리 이력)
    var actor: String? = nil
}

/// 11-4 · 11-7 함께 보면 좋은 규칙 · 공지
struct InquiryReference: Equatable, Sendable {
    enum Kind: String, UnknownCaseDecodable, Encodable, Sendable {
        case rule = "RULE"
        case notice = "NOTICE"
        case unknown = "UNKNOWN"

        static let unknownCase: Kind = .unknown
    }

    let kind: Kind
    /// 규칙은 문서 slug, 공지는 숫자 id. 없으면 목록으로 가요.
    let id: String?
    let title: String
    /// 예) "우선순위, 진행 방법 등"
    let summary: String
}

/// 11-4 문의 상세 · 작성자 / 11-7 반려
struct InquiryDetail: Equatable, Sendable {
    let inquiry: InquirySummary
    let history: [InquiryHistory]
    let reference: InquiryReference?
}

/// 11-2 문의 · 건의 작성 내용
struct InquiryDraft: Equatable, Sendable {
    static let titleLimit = 60
    static let bodyLimit = 2_000

    var department: InquiryDepartment = .nativeOps
    var title = ""
    var body = ""
    var isAnonymous = true
    /// 후속 문의면 원래 문의 ID
    var followUpOf: Int?
}

/// 11-5 받은함의 문의 한 건 (담당자 화면)
struct InquiryInboxItem: Equatable, Identifiable, Sendable {
    let inquiry: InquirySummary
    /// 실명 문의만 있어요. 익명이면 nil (신원을 표시하지 않아요)
    let authorName: String?
    let assignee: String?
    let history: [InquiryHistory]
    let reference: InquiryReference?

    var id: Int { inquiry.id }
}

/// 11-5 문의 받은함 — 내 부서에 배정된 문의만
struct InquiryInbox: Equatable, Sendable {
    let department: InquiryDepartment
    let items: [InquiryInboxItem]
    /// 담당자로 고를 수 있는 사람
    let assignees: [String]
}

/// 11-6 공식 답변 / 반려
struct InquiryReplyDraft: Equatable, Sendable {
    enum Kind: String, Encodable, Sendable {
        case answer = "ANSWER"
        case reject = "REJECT"
    }

    static let bodyLimit = 2_000

    var kind: Kind = .answer
    var body = ""
    /// 함께 보여줄 규칙
    /// 규칙 문서 slug
    var referenceRuleId: String?
}
