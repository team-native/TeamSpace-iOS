import Foundation

/// 08-7 결과 등록 — 참여 확정 · 미선정 모두 사유를 적어야 해요.
struct DecideApplicantUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(projectId: Int, applicant: Applicant, decision: ApplicantDecision, reason: String) async throws -> Applicant {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.invalidInput("결과 안내 사유를 적어 주세요.") }
        guard applicant.status.isCancelable else { throw AppError.invalidInput("이미 결과를 등록한 지원자예요.") }
        return try await projectRepository.decide(
            projectId: projectId,
            applicantId: applicant.id,
            decision: decision,
            reason: trimmed
        )
    }
}
