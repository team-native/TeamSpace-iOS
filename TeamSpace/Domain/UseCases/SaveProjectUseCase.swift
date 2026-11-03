import Foundation

/// 프로젝트 등록 · 수정 — Admin 만. 이름 · PM · 기간 · 진행률을 확인해요.
struct SaveProjectUseCase {
    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    /// 등록하면 새 프로젝트 id(slug), 수정하면 그 id 를 돌려줘요.
    @discardableResult
    func execute(_ draft: ProjectDraft, editingId: String? = nil, user: AuthUser, calendar: Calendar = .current) async throws -> String {
        guard user.can(.registerProjects) else {
            throw AppError.forbidden(editingId == nil ? "프로젝트는 관리자만 등록할 수 있어요." : "프로젝트는 관리자만 고칠 수 있어요.")
        }
        var trimmed = draft
        trimmed.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.pmName = draft.pmName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.name.isEmpty, trimmed.name.count <= ProjectDraft.nameLimit else {
            throw AppError.invalidInput("프로젝트 이름은 1~\(ProjectDraft.nameLimit)자로 써 주세요.")
        }
        guard trimmed.summary.count <= ProjectDraft.summaryLimit else {
            throw AppError.invalidInput("한 줄 설명은 \(ProjectDraft.summaryLimit)자까지 쓸 수 있어요.")
        }
        guard !trimmed.pmName.isEmpty else { throw AppError.invalidInput("PM 이름을 써 주세요.") }
        guard calendar.startOfDay(for: trimmed.endDate) >= calendar.startOfDay(for: trimmed.startDate) else {
            throw AppError.invalidInput("끝나는 날은 시작일보다 뒤로 정해 주세요.")
        }
        trimmed.progress = trimmed.status == .completed ? 100 : min(max(trimmed.progress, 0), 100)
        if let editingId {
            try await projectRepository.updateProject(id: editingId, trimmed)
            return editingId
        }
        return try await projectRepository.createProject(trimmed)
    }
}
