import Foundation

/// 신고 처리 — Admin 만, 대기 중인 신고만 숨김 · 삭제 · 반려해요.
struct DecideReportUseCase {
    private let boardRepository: BoardRepository

    init(boardRepository: BoardRepository) {
        self.boardRepository = boardRepository
    }

    func execute(_ report: PostReportItem, decision: ReportDecision, user: AuthUser) async throws -> PostReportItem {
        guard user.can(.handleReports) else { throw AppError.forbidden("신고는 관리자만 처리할 수 있어요.") }
        guard report.status == .pending else { throw AppError.invalidInput("이미 처리한 신고예요.") }
        try await boardRepository.decideReport(id: report.id, decision: decision)
        var updated = report
        updated.status = decision.status
        updated.handledBy = user.name
        updated.handledAt = Date()
        return updated
    }
}
