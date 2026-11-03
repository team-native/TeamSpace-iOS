import Foundation

/// 신고 관리 목록 — Admin 만. 신고마다 글 제목을 함께 불러와요. (숨김 · 삭제된 글은 제목 없음)
struct FetchReportsUseCase {
    static let pageLimit = 50

    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(user: AuthUser, pendingOnly: Bool) async throws -> [PostReportItem] {
        guard user.can(.handleReports) else { throw AppError.forbidden("신고는 관리자만 처리할 수 있어요.") }
        let reports = try await boardRepository.fetchReports(pendingOnly: pendingOnly, cursor: nil, limit: Self.pageLimit).items
        let titles = await titles(for: Set(reports.map(\.postId)))
        return reports.map { report in
            var item = report
            item.postTitle = titles[report.postId]
            return item
        }
    }

    private func titles(for postIds: Set<Int>) async -> [Int: String] {
        let repository = boardRepository
        return await withTaskGroup(of: (Int, String?).self) { group in
            for id in postIds {
                group.addTask { (id, try? await repository.fetchPost(id: id).post.title) }
            }
            var result: [Int: String] = [:]
            for await (id, title) in group {
                if let title { result[id] = title }
            }
            return result
        }
    }
}
