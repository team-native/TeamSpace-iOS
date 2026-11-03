import XCTest
@testable import TeamSpace

/// 신고 관리 (GET /admin/reports · POST /admin/reports/{id}/decision)
@MainActor
final class ReportTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testPendingReportsWithPostTitles() async throws {
        let viewModel = makeContainer().makeReportListViewModel(user: admin)
        await viewModel.load()

        XCTAssertEqual(viewModel.reports.map(\.id), [3, 2], "대기 중만, 최신순")
        XCTAssertEqual(viewModel.pendingCountText, "대기 중 2건")
        let first = try XCTUnwrap(viewModel.reports.first)
        XCTAssertEqual(first.reason, "욕설·비하")
        XCTAssertEqual(first.titleText, "회식 이시우가 쏘는 거 어떤가요?", "글 제목을 따로 불러와요")
        XCTAssertEqual(viewModel.reports.last?.detailText, "추가 설명 없음")

        await viewModel.select(.all)
        XCTAssertEqual(viewModel.reports.map(\.id), [3, 2, 1])
        XCTAssertEqual(viewModel.reports.last?.handledText, "반려 · 관리자")
    }

    func testHideRemovesPostAndReport() async throws {
        let container = makeContainer()
        let viewModel = container.makeReportListViewModel(user: admin)
        await viewModel.load()

        viewModel.decidingReport = viewModel.reports.first
        await viewModel.decide(.hide)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.toastMessage, "글을 숨겼어요")
        XCTAssertEqual(viewModel.reports.map(\.id), [2], "대기 중 목록에서 빠져요")

        let board = container.makeBoardViewModel()
        await board.load()
        XCTAssertFalse(board.posts.contains { $0.id == 40 }, "숨긴 글은 게시판에 보이지 않아요")

        await viewModel.select(.all)
        let hidden = try XCTUnwrap(viewModel.reports.first { $0.id == 3 })
        XCTAssertEqual(hidden.status, .hidden)
        XCTAssertEqual(hidden.titleText, "볼 수 없는 글 · #40")
    }

    func testRejectKeepsPost() async throws {
        let container = makeContainer()
        let viewModel = container.makeReportListViewModel(user: admin)
        await viewModel.load()
        await viewModel.select(.all)

        viewModel.decidingReport = viewModel.reports.first { $0.id == 2 }
        await viewModel.decide(.reject)
        XCTAssertEqual(viewModel.toastMessage, "신고를 반려했어요")
        let rejected = try XCTUnwrap(viewModel.reports.first { $0.id == 2 })
        XCTAssertEqual(rejected.status, .rejected, "전체 탭에서는 결과를 바로 보여줘요")
        XCTAssertEqual(rejected.handledBy, "관리자")
        XCTAssertEqual(rejected.postTitle, "정산 내역 공개 범위 제안드려요")

        viewModel.decidingReport = rejected
        await viewModel.decide(.delete)
        XCTAssertEqual(viewModel.errorMessage, "이미 처리한 신고예요.")
    }

    func testOnlyAdminHandlesReports() async {
        XCTAssertTrue(admin.can(.handleReports))
        XCTAssertFalse(leader.can(.handleReports), "Leader 도 서버 require_admin 이라 못 봐요")

        let viewModel = makeContainer().makeReportListViewModel(user: leader)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("권한 없음 화면이어야 해요") }
    }

    func testDecisionRequestBody() throws {
        let body = try JSONEncoder().encode(ServerReportDecisionRequestDTO(decision: ReportDecision.delete.rawValue, note: ""))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(object, ["decision": "삭제", "note": ""])
    }
}
