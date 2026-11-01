import Foundation

/// 08-4 참여 신청 — 가능한 시간과 한 마디(300자까지)가 필요해요.
struct ApplyProjectUseCase {
    static let messageLimit = 300

    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    /// 입력이 올바르지 않으면 안내 문구, 괜찮으면 nil
    static func validationMessage(message: String, availability: Availability?) -> String? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if availability == nil || availability == .unknown { return "가능한 시간을 골라 주세요." }
        if trimmed.isEmpty { return "PM에게 전할 한 마디를 적어 주세요." }
        if trimmed.count > messageLimit { return "한 마디는 \(messageLimit)자까지 쓸 수 있어요." }
        return nil
    }

    func execute(projectId: Int, draft: ApplicationDraft) async throws -> ProjectApplication {
        if let message = Self.validationMessage(message: draft.message, availability: draft.availability) {
            throw AppError.invalidInput(message)
        }
        let trimmed = ApplicationDraft(
            openingId: draft.openingId,
            availability: draft.availability,
            message: draft.message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return try await projectRepository.apply(projectId: projectId, draft: trimmed)
    }
}
