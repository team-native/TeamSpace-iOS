import Foundation

/// 결재 탭 — 내가 올린 결재 · 받은 결재
struct ApprovalBox: Equatable, Sendable {
    let mine: [ApprovalItem]
    let received: [ApprovalItem]
}

struct FetchApprovalBoxUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    /// 두 목록을 함께 불러와 최근 순으로 정렬합니다.
    func execute() async throws -> ApprovalBox {
        async let mine = approvalRepository.fetchMyApprovals()
        async let received = approvalRepository.fetchReceivedApprovals()
        return try await ApprovalBox(
            mine: mine.sorted { $0.updatedAt > $1.updatedAt },
            received: received.sorted { $0.updatedAt > $1.updatedAt }
        )
    }
}
