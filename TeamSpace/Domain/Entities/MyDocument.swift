import Foundation

/// 결재선에 있는 사람 (이름 · 부서)
struct DocumentPerson: Equatable, Sendable {
    let name: String
    let department: String
}

/// 07-4 내가 제출한 문서 · 07-5 임시 저장 문서 한 건
/// 05 결재 목록보다 진행 정보(현재 결재자 · 최종 결재 · 반려 사유)가 더 많아요.
struct MyDocument: Equatable, Identifiable, Sendable {
    let id: Int
    let kind: ApprovalKind
    let title: String
    let amount: Int?
    let status: ApprovalStatus
    let projectName: String?
    /// 임시 저장 문서의 작성 중인 내용 요약
    let summary: String?
    /// 작성 중이면 nil
    let submittedAt: Date?
    /// 마지막 저장 · 변경 시각 (임시 저장은 자동 저장 시각)
    let updatedAt: Date
    /// 지금 검토 중인 사람 (대기 · 검토 중일 때만)
    let currentApprover: DocumentPerson?
    /// 예) "1차 검토 대기"
    let currentStepTitle: String?
    /// 승인 · 반려한 사람
    let decidedBy: DocumentPerson?
    let decidedAt: Date?
    let rejectReason: String?

    var isDraft: Bool { status == .draft }
}
