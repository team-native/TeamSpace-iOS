import Foundation

/// 결재 저장소 — TeamSpace-backend develop `workflows.py`
protocol ApprovalRepository: Sendable {
    /// GET /approvals?box=mine — 내가 올린 결재 (임시 저장 포함)
    func fetchMyApprovals() async throws -> [ApprovalItem]
    /// GET /approvals?box=received · handled — 내가 결재자인 결재 (대기 + 처리한 것)
    func fetchReceivedApprovals() async throws -> [ApprovalItem]
    /// GET /approvals/{id} — 결재 상세 · 결재선 · 의견
    func fetchDetail(documentId: Int) async throws -> ApprovalDetail
    /// POST /approvals/{id}/approve · reject — 지금 내 차례인 단계를 처리해요. (반려는 사유 필수)
    func decide(documentId: Int, decision: ApprovalDecision, comment: String?) async throws -> ApprovalDecisionResult
    /// POST /approvals/{id}/comments — 의견 남기기
    func addComment(documentId: Int, body: String) async throws -> ApprovalComment
    /// POST /documents — 업무 문서 작성 및 임시 저장. 새 문서 ID 를 돌려줘요. (다음 묶음에서 /approvals 로)
    func createDocument(_ draft: DocumentDraft) async throws -> Int
    /// POST /documents/{documentId}/submit — 문서 제출 (다음 묶음에서 /approvals 로)
    func submitDocument(documentId: Int) async throws
    /// POST /approvals/{id}/cancel — 요청 취소 (상태가 '취소' 가 돼요)
    func withdraw(documentId: Int) async throws
}
