import Foundation

/// 08-7 지원자 목록 — 검토 중 → 접수 → 결과 순, 같은 상태면 먼저 신청한 사람부터
struct FetchApplicantsUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(projectId: Int) async throws -> ApplicantBoard {
        var board = try await projectRepository.fetchApplicants(projectId: projectId)
        let order: [ApplicationStatus] = [.reviewing, .submitted, .accepted, .declined, .canceled, .unknown]
        board.applicants.sort {
            let left = order.firstIndex(of: $0.status) ?? order.count
            let right = order.firstIndex(of: $1.status) ?? order.count
            return left == right ? $0.appliedAt < $1.appliedAt : left < right
        }
        return board
    }
}
