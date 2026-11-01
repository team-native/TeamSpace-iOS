import Foundation

/// 결재선 한 사람의 상태
enum ApproverStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case waiting = "WAITING"     // 이전 단계 승인 후 차례가 와요
    case reviewing = "REVIEWING" // 지금 검토 중
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case unknown = "UNKNOWN"

    static let unknownCase: ApproverStatus = .unknown
}

/// 결재선 (05-3)
struct Approver: Equatable, Identifiable, Sendable {
    /// 결재 단계 ID — POST /approvals/{approvalId}/decide 에 사용
    let id: Int
    let name: String
    /// 예) OL · FA · Leader
    let role: String
    let status: ApproverStatus
    /// 예) 오늘 10:12 확인 / 이전 단계 승인 후
    let note: String
}

/// 상세 항목 한 줄 (비용 유형 · 프로젝트 · 사용 예정일 …)
struct ApprovalField: Equatable, Sendable {
    let title: String
    let value: String
}

struct ApprovalAttachment: Equatable, Sendable {
    let name: String
    /// 예) 1.2MB
    let sizeText: String
}

struct ApprovalComment: Equatable, Identifiable, Sendable {
    let id: Int
    let authorName: String
    let body: String
    let createdAt: Date
}

/// GET /documents/{documentId} — 문서 상세 및 결재 이력
struct ApprovalDetail: Equatable, Sendable {
    let item: ApprovalItem
    let fields: [ApprovalField]
    let reason: String
    let approvers: [Approver]
    let attachments: [ApprovalAttachment]
    let comments: [ApprovalComment]
    /// 내가 올린 결재인지
    let isMine: Bool
    /// 내가 결재할 차례면 그 단계 ID (아니면 nil)
    let myApprovalId: Int?

    /// 05-4 에서 승인 · 반려 버튼을 보여줄지
    var canDecide: Bool {
        myApprovalId != nil && item.status.isWaiting
    }

    /// 05-3 에서 요청 취소 · 수정하기를 보여줄지
    var canEdit: Bool {
        isMine && (item.status == .draft || item.status.isWaiting)
    }

    /// 지금 검토 중인 결재선 순서 (1부터)
    var currentStep: Int {
        (approvers.firstIndex { $0.status == .reviewing } ?? 0) + 1
    }

    /// 내 다음 결재자 (05-9 "다음 결재자")
    var nextApprover: Approver? {
        guard let myApprovalId, let index = approvers.firstIndex(where: { $0.id == myApprovalId }) else { return nil }
        let next = approvers.index(after: index)
        return next < approvers.endIndex ? approvers[next] : nil
    }
}

/// 승인 · 반려
enum ApprovalDecision: String, Sendable {
    case approve = "APPROVE"
    case reject = "REJECT"
}

/// POST /approvals/{approvalId}/decide 결과
struct ApprovalDecisionResult: Equatable, Sendable {
    let status: ApprovalStatus
    let nextApproverName: String?
}
