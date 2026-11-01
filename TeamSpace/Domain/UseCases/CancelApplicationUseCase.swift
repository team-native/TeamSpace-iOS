import Foundation

/// 08-6 신청 취소 — 결과가 나기 전까지만 취소할 수 있어요.
struct CancelApplicationUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(_ application: ProjectApplication) async throws {
        guard application.status.isCancelable else {
            throw AppError.invalidInput("결과가 확정된 신청은 취소할 수 없어요.")
        }
        try await projectRepository.cancelApplication(id: application.id)
    }
}
