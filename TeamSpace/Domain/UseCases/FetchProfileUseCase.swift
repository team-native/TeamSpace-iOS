import Foundation

/// 07-13 내 프로필 불러오기
struct FetchProfileUseCase {
    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    func execute() async throws -> MyProfile {
        try await workspaceRepository.fetchProfile()
    }
}
