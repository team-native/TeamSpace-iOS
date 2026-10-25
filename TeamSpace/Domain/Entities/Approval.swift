import Foundation

/// 결재 상태 (05-1 상단 요약 순서와 같아요)
enum ApprovalStatus: String, UnknownCaseDecodable, Hashable, CaseIterable, Sendable {
    case draft = "DRAFT"           // 작성 중 (임시 저장)
    case pending = "PENDING"       // 결재 대기
    case reviewing = "IN_REVIEW"   // 검토 중
    case approved = "APPROVED"     // 승인
    case rejected = "REJECTED"     // 반려
    case unknown = "UNKNOWN"

    static let unknownCase: ApprovalStatus = .unknown

    /// 결재자가 아직 처리해야 하는 상태
    var isWaiting: Bool {
        self == .pending || self == .reviewing
    }

    /// 처리가 끝난 상태
    var isHandled: Bool {
        self == .approved || self == .rejected
    }
}

/// 결재 종류
enum ApprovalKind: String, UnknownCaseDecodable, Hashable, Sendable {
    case expense = "EXPENSE"   // 비용 승인
    case staffing = "STAFFING" // 프로젝트 인력 지원
    case other = "ETC"
    case unknown = "UNKNOWN"

    static let unknownCase: ApprovalKind = .unknown
}

/// 05-1 · 05-2 결재 목록 한 건
struct ApprovalItem: Equatable, Identifiable, Sendable {
    let id: Int
    let kind: ApprovalKind
    let title: String
    /// 비용 결재 금액 (인력 지원 등은 nil)
    let amount: Int?
    let status: ApprovalStatus
    /// 올린 사람
    let requesterName: String
    /// 예) PMO · Design
    let requesterDepartment: String
    /// 예) iOS 1명 · 8월~10월
    let summary: String?
    let updatedAt: Date
}
