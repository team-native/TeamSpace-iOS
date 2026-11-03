import Foundation
import Observation

/// 일정 추가 [Admin] — POST /admin/events
@Observable
@MainActor
final class ScheduleComposeViewModel {
    var draft: ScheduleDraft
    private(set) var isSubmitting = false
    /// 등록을 마쳤는지 (알림을 띄운 뒤 닫아요)
    var didCreate = false
    var errorMessage: String?

    private let user: AuthUser
    private let createScheduleUseCase: CreateScheduleUseCase

    init(user: AuthUser, createScheduleUseCase: CreateScheduleUseCase, date: Date = Date()) {
        self.user = user
        self.createScheduleUseCase = createScheduleUseCase
        draft = ScheduleDraft(date: date)
    }

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
            try await createScheduleUseCase.execute(draft, user: user)
            didCreate = true
        } catch {
            AppLog.record(error, context: "workspace.schedule.create")
            errorMessage = error.userMessage
        }
    }
}
