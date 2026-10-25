import Foundation

struct DecideApprovalUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    /// 반려는 사유가 꼭 있어야 해요. (요청자에게 그대로 전달)
    func execute(approvalId: Int, decision: ApprovalDecision, comment: String?) async throws -> ApprovalDecisionResult {
        let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        if decision == .reject, (trimmed ?? "").isEmpty {
            throw AppError.invalidInput("반려 사유를 입력해 주세요.")
        }
        return try await approvalRepository.decide(
            approvalId: approvalId,
            decision: decision,
            comment: (trimmed ?? "").isEmpty ? nil : trimmed
        )
    }
}
