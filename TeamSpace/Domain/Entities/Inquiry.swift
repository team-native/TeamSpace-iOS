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
    /// 없으면 목록으로 가요.
    let id: Int?
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
