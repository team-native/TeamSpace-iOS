import Foundation

/// 07-11 내 운영 제안 — 최근 작성 순
struct FetchMyProposalsUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> [MyProposal] {
        try await workspaceRepository.fetchMyProposals().sorted { $0.createdAt > $1.createdAt }
    }
}
