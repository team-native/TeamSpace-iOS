import Foundation

/// 규칙 문서 등록 · 개정 — Admin 만. 제목 · 조항 · 개정 사유를 확인해요.
struct SaveRuleUseCase {
    private let ruleRepository: RuleRepository

    init(ruleRepository: RuleRepository) {
        self.ruleRepository = ruleRepository
    }

    /// 저장한 문서 slug 를 돌려줘요.
    @discardableResult
    func execute(_ draft: RuleDraft, user: AuthUser, now: Date = Date()) async throws -> String {
        guard user.can(.manageDocs) else {
            throw AppError.forbidden(draft.isRevision ? "규칙은 관리자만 개정할 수 있어요." : "규칙은 관리자만 등록할 수 있어요.")
        }
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.articles = draft.articles.compactMap { article in
            var cleaned = article
            cleaned.title = article.title.trimmingCharacters(in: .whitespacesAndNewlines)
            cleaned.body = article.body.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.title.isEmpty && cleaned.body.isEmpty ? nil : cleaned
        }
        guard !trimmed.title.isEmpty, trimmed.title.count <= RuleDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(RuleDraft.titleLimit)자로 써 주세요.")
        }
        guard trimmed.summary.count <= RuleDraft.summaryLimit else {
            throw AppError.invalidInput("요약은 \(RuleDraft.summaryLimit)자까지 쓸 수 있어요.")
        }
        guard !trimmed.articles.isEmpty else { throw AppError.invalidInput("조항을 하나 이상 써 주세요.") }
        guard trimmed.articles.allSatisfy({ !$0.title.isEmpty && !$0.body.isEmpty }) else {
            throw AppError.invalidInput("조항마다 제목과 내용을 써 주세요.")
        }
        if trimmed.isRevision {
            guard !trimmed.note.isEmpty, trimmed.note.count <= RuleDraft.noteLimit else {
                throw AppError.invalidInput("개정 사유를 1~\(RuleDraft.noteLimit)자로 써 주세요.")
            }
        }
        let slug = trimmed.editingSlug ?? Self.newSlug(now: now)
        return try await ruleRepository.saveRule(trimmed, slug: slug)
    }

    /// 새 문서 slug — "rule-20261103-1530" (한글 제목이라 시각으로 만들어요)
    static func newSlug(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "rule-\(formatter.string(from: now))"
    }
}
