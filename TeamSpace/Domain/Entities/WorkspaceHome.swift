import Foundation

/// GET /workspace/home — 07-1 내 공간 대시보드 한 화면에 필요한 요약
struct WorkspaceHome: Equatable, Sendable {
    /// "NativeLab / Design"
    let affiliation: String
    let todo: WorkspaceTodoSummary
    let notification: WorkspaceNotificationPreview?
    /// 내가 검토할 결재 (없으면 nil)
    let receivedApproval: WorkspaceApprovalPreview?
    /// 가장 최근에 제출한 문서 (없으면 nil)
    let submittedDocument: WorkspaceSubmittedDocument?
    let projects: [WorkspaceProject]
    let schedules: [WorkspaceSchedule]
    let records: WorkspaceRecords
}

/// 나의 To-do 요약
struct WorkspaceTodoSummary: Equatable, Sendable {
    let todayCount: Int
    let completedCount: Int
    /// 오늘 할 일 제목 (앞에서부터 몇 개만)
    let todayTitles: [String]
}

/// 내 알림 — 개인 업무 알림 중 안 읽은 것
struct WorkspaceNotificationPreview: Equatable, Sendable {
    let unreadCount: Int
    let title: String
    /// 예) "10.23 15:00–16:00 · 온라인"
    let subtitle: String
}

/// 받은 결재
struct WorkspaceApprovalPreview: Equatable, Sendable {
    let documentId: Int
    let waitingCount: Int
    let title: String
    let requesterName: String
    let requestedAt: Date
}

/// 내가 제출한 문서
struct WorkspaceSubmittedDocument: Equatable, Sendable {
    let documentId: Int
    let title: String
    let amount: Int?
    let submittedAt: Date
    let status: ApprovalStatus
    /// 지금 검토 중인 사람 (검토 전 · 완료면 nil)
    let currentApproverName: String?
}

/// 참여 프로젝트
struct WorkspaceProject: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let pmName: String
    let team: String
    let memberCount: Int
    /// 0~100
    let progress: Int
}

/// 일정 구분 — 개인 업무 · Native 전체 일정
enum WorkspaceScheduleScope: String, UnknownCaseDecodable, Encodable, Hashable, Sendable {
    case personal = "PERSONAL"
    case team = "TEAM"
    case unknown = "UNKNOWN"

    static let unknownCase: WorkspaceScheduleScope = .unknown
}

/// 예정 일정
struct WorkspaceSchedule: Equatable, Identifiable, Sendable {
    let id: Int
    let scope: WorkspaceScheduleScope
    let title: String
    let startsAt: Date
    let endsAt: Date
    let place: String
    /// 덧붙임 (예: "변경자 이시우", "NativeOps")
    let note: String?
}

/// 운영 제안 상태
enum ProposalStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case reviewing = "IN_REVIEW"
    /// 운영진이 공식 답변을 남김
    case answered = "ANSWERED"
    case adopted = "ADOPTED"
    case closed = "CLOSED"
    case unknown = "UNKNOWN"

    static let unknownCase: ProposalStatus = .unknown
}

/// 문의 상태
enum InquiryStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case reviewing = "IN_REVIEW"
    case answered = "ANSWERED"
    case rejected = "REJECTED"
    case unknown = "UNKNOWN"

    static let unknownCase: InquiryStatus = .unknown
}

/// 내가 남긴 기록 — 글 · 댓글 / 운영 제안 / 문의
struct WorkspaceRecords: Equatable, Sendable {
    let latestPost: WorkspacePostPreview?
    let proposalCount: Int
    let latestProposal: WorkspaceProposalPreview?
    let inquiries: [WorkspaceInquiryPreview]
}

struct WorkspacePostPreview: Equatable, Sendable {
    let title: String
    let createdAt: Date
}

struct WorkspaceProposalPreview: Equatable, Sendable {
    let title: String
    let status: ProposalStatus
    let recommendCount: Int
}

struct WorkspaceInquiryPreview: Equatable, Sendable {
    let title: String
    let status: InquiryStatus
}
