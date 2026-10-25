import Foundation

/// 결재 저장소
/// 목록 API 는 명세서에 없어 경로를 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol ApprovalRepository: Sendable {
    /// GET /approvals/mine — 내가 올린 결재 (임시 저장 포함)
    func fetchMyApprovals() async throws -> [ApprovalItem]
    /// GET /approvals/received — 내가 결재자인 결재 (대기 + 처리한 것)
    func fetchReceivedApprovals() async throws -> [ApprovalItem]
}
