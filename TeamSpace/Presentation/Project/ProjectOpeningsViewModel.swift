import Foundation
import Observation

/// 모집 자리 관리 [Admin] — 상세를 불러와 자리를 더하고 고치고 지운 뒤 한 번에 저장해요. (PATCH /admin/projects/{id})
@Observable
@MainActor
final class ProjectOpeningsViewModel {
    private(set) var state: ViewState<ProjectDetail> = .idle
    private(set) var openings: [OpeningDraft] = []
    /// 시트에서 고치는 중인 자리 (새 자리면 목록에 없는 id)
    var editing: OpeningDraft?
    private(set) var isSaving = false
    private(set) var hasChanges = false
    var didSave = false
    var errorMessage: String?

    let projectId: String
    private let user: AuthUser
    private let fetchProjectDetailUseCase: FetchProjectDetailUseCase
    private let updateProjectOpeningsUseCase: UpdateProjectOpeningsUseCase

    init(
        projectId: String,
        user: AuthUser,
        fetchProjectDetailUseCase: FetchProjectDetailUseCase,
        updateProjectOpeningsUseCase: UpdateProjectOpeningsUseCase
    ) {
        self.projectId = projectId
        self.user = user
        self.fetchProjectDetailUseCase = fetchProjectDetailUseCase
        self.updateProjectOpeningsUseCase = updateProjectOpeningsUseCase
    }

    var canManage: Bool { user.can(.registerProjects) }
    var projectName: String { state.value?.project.name ?? "" }

    /// "모집 중 2자리 · 3명"
    var summaryText: String {
        openings.isEmpty ? "모집 중인 자리가 없어요" : "모집 중 \(openings.count)자리 · \(openings.map(\.headcount).reduce(0, +))명"
    }

    var saveTitle: String { openings.isEmpty ? "모집 마감으로 저장" : "모집 자리 저장" }
    var canSave: Bool { canManage && hasChanges && !isSaving }

    var isEditingNew: Bool {
        guard let editing else { return false }
        return !openings.contains { $0.id == editing.id }
    }

    /// 시트의 저장 버튼 — 직군이 있어야 해요.
    var canApplyEditing: Bool {
        guard let editing else { return false }
        return !editing.role.trimmingCharacters(in: .whitespaces).isEmpty && editingHint == nil
    }

    var editingHint: String? {
        guard let editing else { return nil }
        if Calendar.current.startOfDay(for: editing.endDate) < Calendar.current.startOfDay(for: editing.startDate) {
            return "모집 마감일은 시작일보다 뒤로 정해 주세요."
        }
        if editing.description.count > OpeningDraft.descriptionLimit {
            return "설명은 \(OpeningDraft.descriptionLimit)자까지 쓸 수 있어요."
        }
        return nil
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let detail = try await fetchProjectDetailUseCase.execute(id: projectId)
            state = .loaded(detail)
            openings = detail.project.openings.map { OpeningDraft(editing: $0) }
            hasChanges = false
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.openings.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func startAdding() { editing = OpeningDraft() }

    func startEditing(_ opening: OpeningDraft) { editing = opening }

    func applyEditing() {
        guard let draft = editing, canApplyEditing else { return }
        do {
            let valid = try UpdateProjectOpeningsUseCase.validated(draft)
            if let index = openings.firstIndex(where: { $0.id == valid.id }) {
                openings[index] = valid
            } else {
                openings.append(valid)
            }
            hasChanges = true
            editing = nil
        } catch {
            errorMessage = error.userMessage
        }
    }

    func remove(_ opening: OpeningDraft) {
        openings.removeAll { $0.id == opening.id }
        hasChanges = true
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await updateProjectOpeningsUseCase.execute(projectId: projectId, openings, user: user)
            hasChanges = false
            didSave = true
        } catch {
            AppLog.record(error, context: "project.openings.save")
            errorMessage = error.userMessage
        }
    }
}

extension OpeningDraft {
    /// "iOS 개발 1명 · 11.01 – 11.15"
    var summaryText: String {
        "\(displayTitle) \(headcount)명 · \(TSFormat.shortDate(startDate)) – \(TSFormat.shortDate(endDate))"
    }
}
