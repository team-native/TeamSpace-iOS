import Foundation
import Observation

/// 규칙 문서 등록 · 개정 [Admin] — POST /admin/docs
@Observable
@MainActor
final class RuleComposeViewModel {
    var draft: RuleDraft
    private(set) var isSubmitting = false
    var didSave = false
    private(set) var savedSlug: String?
    var errorMessage: String?

    private let user: AuthUser
    private let saveRuleUseCase: SaveRuleUseCase

    init(user: AuthUser, saveRuleUseCase: SaveRuleUseCase, editing detail: RuleDetail? = nil) {
        self.user = user
        self.saveRuleUseCase = saveRuleUseCase
        draft = detail.map { RuleDraft(editing: $0) } ?? RuleDraft()
    }

    var isRevision: Bool { draft.isRevision }
    var screenTitle: String { isRevision ? "규칙 개정" : "규칙 등록" }
    var submitTitle: String { isRevision ? "개정하기" : "규칙 등록" }
    var completionTitle: String { isRevision ? "규칙을 개정했어요" : "규칙을 등록했어요" }
    var noticeText: String {
        isRevision
            ? "이전 판은 변경 내역에 남고, 버전이 하나 올라가요. 바뀐 조항은 ‘개정’으로 표시돼요."
            : "등록하면 규칙 · 제도 목록에 v1.0으로 올라가요."
    }

    /// 바뀐 조항 수 (개정일 때만)
    var changedCountText: String? {
        guard isRevision else { return nil }
        let count = draft.articles.filter(\.isChanged).count
        return count == 0 ? "아직 바뀐 조항이 없어요" : "바뀐 조항 \(count)개"
    }

    var canSubmit: Bool {
        guard !isSubmitting, !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let filled = draft.articles.contains { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasNote = !isRevision || !draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return filled && hasNote
    }

    func addArticle() {
        draft.articles.append(RuleDraft.Article())
    }

    func removeArticle(_ article: RuleDraft.Article) {
        guard draft.articles.count > 1 else { return }
        draft.articles.removeAll { $0.id == article.id }
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            savedSlug = try await saveRuleUseCase.execute(draft, user: user)
            didSave = true
        } catch {
            AppLog.record(error, context: isRevision ? "rule.revise" : "rule.create")
            errorMessage = error.userMessage
        }
    }
}
