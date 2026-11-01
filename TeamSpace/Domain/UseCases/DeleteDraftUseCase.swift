import Foundation

/// 07-5 임시 문서 삭제 — 아직 제출하지 않은 문서만 지울 수 있어요.
struct DeleteDraftUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute(_ document: MyDocument) async throws {
        guard document.isDraft else {
            throw AppError.invalidInput("제출한 문서는 삭제할 수 없어요. 결재 상세에서 요청을 취소해 주세요.")
        }
        try await workspaceRepository.deleteDraft(documentId: document.id)
    }
}
