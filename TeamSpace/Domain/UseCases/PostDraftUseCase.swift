import Foundation

/// 10-2 임시 저장 — 빈 글은 저장하지 않아요.
struct PostDraftUseCase {
    private let postDraftRepository: PostDraftRepository

    init(postDraftRepository: PostDraftRepository) {
        self.postDraftRepository = postDraftRepository
    }

    func fetch() -> PostDraft? {
        postDraftRepository.fetch()
    }

    /// 저장했으면 true
    @discardableResult
    func save(_ draft: PostDraft) -> Bool {
        guard !draft.isEmpty else { return false }
        postDraftRepository.save(draft)
        return true
    }

    func clear() {
        postDraftRepository.clear()
    }
}
