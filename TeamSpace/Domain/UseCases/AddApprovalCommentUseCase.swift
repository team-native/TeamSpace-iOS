import Foundation

struct AddApprovalCommentUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    func execute(documentId: Int, body: String) async throws -> ApprovalComment {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.invalidInput("의견을 입력해 주세요.") }
        return try await approvalRepository.addComment(documentId: documentId, body: trimmed)
    }
}
