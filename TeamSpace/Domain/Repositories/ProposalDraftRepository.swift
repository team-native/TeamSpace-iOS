import Foundation

/// 12-3 "임시 저장" — 기기에만 저장해요.
protocol ProposalDraftRepository: Sendable {
    func fetch() -> ProposalDraft?
    func save(_ draft: ProposalDraft)
    func clear()
}
