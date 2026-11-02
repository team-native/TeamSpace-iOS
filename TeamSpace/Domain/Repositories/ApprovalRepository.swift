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
    /// POST /approvals — 작성(임시 저장, submit false) · 제출(submit true)을 한 번에. 새 결재 ID 를 돌려줘요.
    func createDocument(_ draft: DocumentDraft, submit: Bool) async throws -> Int
    /// PATCH /approvals/{id} — 작성 중 · 반려된 내 결재를 고쳐 다시 저장(submit false) · 제출(submit true)해요.
    func updateDocument(documentId: Int, _ draft: DocumentDraft, submit: Bool) async throws -> Int
    /// POST /approvals/{id}/cancel — 요청 취소 (상태가 '취소' 가 돼요)
    func withdraw(documentId: Int) async throws
}
