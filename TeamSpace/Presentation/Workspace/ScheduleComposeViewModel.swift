import Foundation
import Observation

/// 일정 추가 · 수정 [Admin] — POST /admin/events · PATCH /admin/events/{id}
@Observable
@MainActor
final class ScheduleComposeViewModel {
    var draft: ScheduleDraft
    private(set) var isSubmitting = false
    /// 등록을 마쳤는지 (알림을 띄운 뒤 닫아요)
    var didCreate = false
    var errorMessage: String?
    /// 수정 중인 일정 번호 (없으면 새 일정)
    let editingScheduleId: Int?

    private let user: AuthUser
    private let createScheduleUseCase: CreateScheduleUseCase
    private let updateScheduleUseCase: UpdateScheduleUseCase?

    init(
        user: AuthUser,
        createScheduleUseCase: CreateScheduleUseCase,
        updateScheduleUseCase: UpdateScheduleUseCase? = nil,
        date: Date = Date(),
        editing detail: ScheduleEventDetail? = nil
    ) {
        self.user = user
        self.createScheduleUseCase = createScheduleUseCase
        self.updateScheduleUseCase = updateScheduleUseCase
        editingScheduleId = detail?.event.id
        draft = detail.map { ScheduleDraft(editing: $0) } ?? ScheduleDraft(date: date)
    }

    var isEditing: Bool { editingScheduleId != nil }
    var screenTitle: String { isEditing ? "일정 수정" : "일정 추가" }
    var submitTitle: String { isEditing ? "수정 완료" : "일정 등록" }
    var completionTitle: String { isEditing ? "일정을 수정했어요" : "일정을 등록했어요" }
    var noticeText: String { isEditing ? "바뀐 내용이 있으면 구성원에게 일정 변경 알림이 가요." : "등록하면 구성원에게 새 일정 알림이 가요." }

    var canSubmit: Bool {
        !isSubmitting && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 끝 시각이 시작보다 빠르면 아래에 안내해요.
    var timeHint: String? {
        let calendar = Calendar.current
        guard CreateScheduleUseCase.minutes(draft.endsAt, calendar) <= CreateScheduleUseCase.minutes(draft.startsAt, calendar) else {
            return nil
        }
        return "끝나는 시각은 시작 시각보다 뒤로 정해 주세요."
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            if let editingScheduleId, let updateScheduleUseCase {
                try await updateScheduleUseCase.execute(id: editingScheduleId, draft, user: user)
            } else {
                try await createScheduleUseCase.execute(draft, user: user)
            }
            didCreate = true
        } catch {
            AppLog.record(error, context: isEditing ? "workspace.schedule.update" : "workspace.schedule.create")
            errorMessage = error.userMessage
        }
    }
}
