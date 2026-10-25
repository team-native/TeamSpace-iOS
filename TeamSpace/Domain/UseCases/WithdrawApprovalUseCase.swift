import Foundation

struct WithdrawApprovalUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    func execute(documentId: Int) async throws {
        try await approvalRepository.withdraw(documentId: documentId)
    }
}
