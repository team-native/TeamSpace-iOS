import Foundation
import Observation

/// 08-3 모집 공고 · 08-4 참여 신청 시트 · 08-5 신청 완료
@Observable
@MainActor
final class RecruitmentViewModel {
    private(set) var state: ViewState<RecruitmentPost> = .idle
    var isApplySheetPresented = false
    var availability: Availability? = .tenHours
    var message = ""
    private(set) var isSubmitting = false
    /// 08-5 "신청을 보냈어요"
    var isSubmittedAlertPresented = false
    var errorMessage: String?

    private let projectId: Int
    private let fetchRecruitmentUseCase: FetchRecruitmentUseCase
    private let applyProjectUseCase: ApplyProjectUseCase

    init(projectId: Int, fetchRecruitmentUseCase: FetchRecruitmentUseCase, applyProjectUseCase: ApplyProjectUseCase) {
        self.projectId = projectId
        self.fetchRecruitmentUseCase = fetchRecruitmentUseCase
        self.applyProjectUseCase = applyProjectUseCase
    }

    var post: RecruitmentPost? { state.value }

    var canSubmit: Bool {
        !isSubmitting && ApplyProjectUseCase.validationMessage(message: message, availability: availability) == nil
    }

    /// "1/300"
    var messageCountText: String {
        "\(message.count)/\(ApplyProjectUseCase.messageLimit)"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchRecruitmentUseCase.execute(projectId: projectId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.recruitment.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func submit() async {
        guard let post = post, let availability = availability, canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await applyProjectUseCase.execute(
                projectId: projectId,
                draft: ApplicationDraft(openingId: post.opening.id, availability: availability, message: message)
            )
            isApplySheetPresented = false
            isSubmittedAlertPresented = true
            message = ""
            await load()
        } catch {
            AppLog.record(error, context: "project.apply")
            errorMessage = error.userMessage
        }
    }
}
