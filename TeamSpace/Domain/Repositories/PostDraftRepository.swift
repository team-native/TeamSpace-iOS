import Foundation

/// 10-2 "임시 저장" — 기기에만 저장해요.
protocol PostDraftRepository: Sendable {
    func fetch() -> PostDraft?
    func save(_ draft: PostDraft)
    func clear()
}
