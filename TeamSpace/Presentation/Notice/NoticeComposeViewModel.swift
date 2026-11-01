import Foundation
import Observation

/// 10-7 전체 공지 작성 [담당자 운영 화면]
@Observable
@MainActor
final class NoticeComposeViewModel {
    var draft: NoticeDraft
    private(set) var isSubmitting = false
    /// 게시 · 예약 · 임시 저장 뒤 알림 문구 (확인하면 화면을 닫아요)
    var completionMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let publishNoticeUseCase: PublishNoticeUseCase
    private let now: () -> Date

    init(user: AuthUser, publishNoticeUseCase: PublishNoticeUseCase, now: @escaping () -> Date = { Date() }) {
        self.user = user
        self.publishNoticeUseCase = publishNoticeUseCase
        self.now = now
        draft = NoticeDraft(scheduledAt: Self.defaultSchedule(now: now()))
    }

    /// 내일 오전 9시
    static func defaultSchedule(now: Date, calendar: Calendar = .current) -> Date {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    var canPublish: Bool {
        !isSubmitting
            && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canAddAttachment: Bool { draft.attachments.count < NoticeDraft.attachmentLimit }

    /// 첨부 추가 — 최대 5개 · 개당 20MB
    func addAttachment(fileName: String, data: Data) {
        guard canAddAttachment, data.count <= NoticeDraft.attachmentByteLimit else {
            errorMessage = "첨부는 최대 \(NoticeDraft.attachmentLimit)개, 개당 20MB까지 올릴 수 있어요."
            return
        }
        draft.attachments.append(NoticeAttachment(fileName: fileName, data: data))
    }

    func removeAttachment(_ attachment: NoticeAttachment) {
        draft.attachments.removeAll { $0.id == attachment.id }
    }

    func publish() async {
        await submit(asDraft: false)
    }

    func saveDraft() async {
        await submit(asDraft: true)
    }

    private func submit(asDraft: Bool) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await publishNoticeUseCase.execute(draft, user: user, asDraft: asDraft, now: now())
            if asDraft {
                completionMessage = "공지를 임시 저장했어요."
            } else if draft.timing == .scheduled {
                completionMessage = "\(NoticeDraft.scheduleText(draft.scheduledAt))에 예약 게시돼요."
            } else {
                completionMessage = "공지를 게시했어요."
            }
        } catch {
            AppLog.record(error, context: "notice.publish")
            errorMessage = error.userMessage
        }
    }
}
