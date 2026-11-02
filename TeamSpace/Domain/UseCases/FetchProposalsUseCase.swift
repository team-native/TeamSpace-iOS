import Foundation

/// 12-1b 운영 제안 목록 — 부서 · 상태 · 진행 단계 칩을 화면에서 거르기 때문에 끝까지 모아 와요.
/// (한 번에 100건, 최대 `maxPages` 페이지)
struct FetchProposalsUseCase {
    static let pageSize = 100
    static let maxPages = 5

    private let proposalRepository: ProposalRepository

    init(proposalRepository: ProposalRepository) {
        self.proposalRepository = proposalRepository
    }

    func execute() async throws -> [ProposalSummary] {
        var items: [ProposalSummary] = []
        var cursor: String?
        for _ in 0..<Self.maxPages {
            let page = try await proposalRepository.fetchProposals(cursor: cursor, limit: Self.pageSize)
            items = items.appendingUnique(page.items)
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }
}
