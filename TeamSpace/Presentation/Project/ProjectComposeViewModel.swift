import Foundation
import Observation

/// 프로젝트 등록 · 수정 [Admin] — POST /admin/projects · PATCH /admin/projects/{id}
@Observable
@MainActor
final class ProjectComposeViewModel {
    var draft: ProjectDraft
    private(set) var isSubmitting = false
    /// 저장을 마쳤는지 (알림을 띄운 뒤 닫아요)
    var didSave = false
    private(set) var savedProjectId: String?
    var errorMessage: String?
    /// 수정 중인 프로젝트 id (없으면 새 프로젝트)
    let editingProjectId: String?

    private let user: AuthUser
    private let saveProjectUseCase: SaveProjectUseCase

    init(user: AuthUser, saveProjectUseCase: SaveProjectUseCase, editing project: ProjectSummary? = nil) {
        self.user = user
        self.saveProjectUseCase = saveProjectUseCase
        editingProjectId = project?.id
        draft = project.map { ProjectDraft(editing: $0) } ?? ProjectDraft()
    }

    var isEditing: Bool { editingProjectId != nil }
    var screenTitle: String { isEditing ? "프로젝트 수정" : "프로젝트 등록" }
    var submitTitle: String { isEditing ? "수정 완료" : "프로젝트 등록" }
    var completionTitle: String { isEditing ? "프로젝트를 수정했어요" : "프로젝트를 등록했어요" }
    var noticeText: String {
        isEditing ? "참여자와 모집 자리는 그대로 남아요." : "등록하면 전체 프로젝트 목록에 바로 보여요. 참여자와 모집 자리는 나중에 더할 수 있어요."
    }

    static let statuses: [ProjectRunStatus] = [.planned, .inProgress, .completed]
    static let departments = Department.selectable.map(\.rawValue)

    /// 완료면 진행률은 100% 로 저장해요.
    var isProgressLocked: Bool { draft.status == .completed }

    var canSubmit: Bool {
        !isSubmitting
            && !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.pmName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && periodHint == nil
    }

    var periodHint: String? {
        let calendar = Calendar.current
        guard calendar.startOfDay(for: draft.endDate) < calendar.startOfDay(for: draft.startDate) else { return nil }
        return "끝나는 날은 시작일보다 뒤로 정해 주세요."
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            savedProjectId = try await saveProjectUseCase.execute(draft, editingId: editingProjectId, user: user)
            didSave = true
        } catch {
            AppLog.record(error, context: isEditing ? "project.update" : "project.create")
            errorMessage = error.userMessage
        }
    }
}
