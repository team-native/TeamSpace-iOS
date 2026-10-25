import Foundation

struct FetchApprovalDetailUseCase {
    private let approvalRepository: ApprovalRepository

    init(approvalRepository: ApprovalRepository) {
        self.approvalRepository = approvalRepository
    }

    /// 코멘트는 오래된 순으로 보여줍니다.
    func execute(documentId: Int) async throws -> ApprovalDetail {
        let detail = try await approvalRepository.fetchDetail(documentId: documentId)
        return ApprovalDetail(
            item: detail.item,
            fields: detail.fields,
            reason: detail.reason,
            approvers: detail.approvers,
            attachments: detail.attachments,
            comments: detail.comments.sorted { $0.createdAt < $1.createdAt },
            isMine: detail.isMine,
            myApprovalId: detail.myApprovalId
        )
    }
}
