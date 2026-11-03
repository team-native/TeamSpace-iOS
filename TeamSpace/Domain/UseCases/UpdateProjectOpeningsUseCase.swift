import Foundation

/// 모집 자리 저장 — Admin 만. 직군 · 기간 · 설명 길이를 확인하고 목록 전체를 보내요. (빈 목록이면 모집 마감)
struct UpdateProjectOpeningsUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    func execute(projectId: String, _ openings: [OpeningDraft], user: AuthUser, calendar: Calendar = .current) async throws {
        guard user.can(.registerProjects) else { throw AppError.forbidden("모집 자리는 관리자만 바꿀 수 있어요.") }
        try await projectRepository.updateOpenings(projectId: projectId, try openings.map { try Self.validated($0, calendar: calendar) })
    }

    static func validated(_ draft: OpeningDraft, calendar: Calendar = .current) throws -> OpeningDraft {
        var trimmed = draft
        trimmed.role = draft.role.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.role.isEmpty else { throw AppError.invalidInput("직군을 써 주세요.") }
        guard OpeningDraft.headcountRange.contains(trimmed.headcount) else {
            throw AppError.invalidInput("모집 인원은 \(OpeningDraft.headcountRange.lowerBound)~\(OpeningDraft.headcountRange.upperBound)명으로 정해 주세요.")
        }
        guard calendar.startOfDay(for: trimmed.endDate) >= calendar.startOfDay(for: trimmed.startDate) else {
            throw AppError.invalidInput("모집 마감일은 시작일보다 뒤로 정해 주세요.")
        }
        guard trimmed.description.count <= OpeningDraft.descriptionLimit else {
            throw AppError.invalidInput("설명은 \(OpeningDraft.descriptionLimit)자까지 쓸 수 있어요.")
        }
        return trimmed
    }
}
