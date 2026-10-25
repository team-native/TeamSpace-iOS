import Foundation

/// 결재 저장소
/// 목록 API 는 명세서에 없어 경로를 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol ApprovalRepository: Sendable {
    /// GET /approvals/mine — 내가 올린 결재 (임시 저장 포함)
    func fetchMyApprovals() async throws -> [ApprovalItem]
    /// GET /approvals/received — 내가 결재자인 결재 (대기 + 처리한 것)
    func fetchReceivedApprovals() async throws -> [ApprovalItem]
    /// GET /documents/{documentId} — 문서 상세 및 결재 이력
    func fetchDetail(documentId: Int) async throws -> ApprovalDetail
    /// POST /approvals/{approvalId}/decide — 승인 · 반려 (반려는 사유 필수)
    func decide(approvalId: Int, decision: ApprovalDecision, comment: String?) async throws -> ApprovalDecisionResult
    /// POST /documents/{documentId}/comments — 의견 남기기 (명세서에 없음)
    func addComment(documentId: Int, body: String) async throws -> ApprovalComment
    /// POST /documents — 업무 문서 작성 및 임시 저장. 새 문서 ID 를 돌려줘요.
    func createDocument(_ draft: DocumentDraft) async throws -> Int
    /// POST /documents/{documentId}/submit — 문서 제출 (결재 요청)
    func submitDocument(documentId: Int) async throws
    /// POST /documents/{documentId}/withdraw — 요청 취소 (명세서에 없음)
    func withdraw(documentId: Int) async throws
}
