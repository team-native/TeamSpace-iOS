import XCTest
@testable import TeamSpace

@MainActor
final class ProposalTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 12-1b 운영 제안 목록

    func testListSortAndPhase() async {
        let viewModel = makeContainer().makeProposalListViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.proposals.map(\.id), [16, 12, 15, 11, 14, 9, 13], "최신순")
        XCTAssertEqual(viewModel.proposals.first?.authorDateText.hasPrefix("익명 · "), true)
        XCTAssertEqual(viewModel.proposals.first?.countText, "댓글 7 · 추천 32")

        viewModel.sort = .recommended
        XCTAssertEqual(viewModel.proposals.map(\.id), [14, 16, 12, 15, 11, 13, 9])

        viewModel.sort = .latest
        viewModel.togglePhase(.ongoing)
        XCTAssertEqual(viewModel.proposals.map(\.id), [16, 12, 15, 11, 13])
        viewModel.togglePhase(.done)
        XCTAssertEqual(viewModel.proposals.map(\.id), [14, 9])
        viewModel.togglePhase(.done)
        XCTAssertNil(viewModel.phase, "다시 누르면 꺼져요")
    }

    func testDepartmentAndStatusMenus() async {
        let viewModel = makeContainer().makeProposalListViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.departments, ["NativeOps", "NativeLab", "PMO", "FA"])
        XCTAssertEqual(viewModel.statuses, [.received, .reviewing, .inProgress, .completed, .answered])

        viewModel.department = "NativeOps"
        XCTAssertEqual(viewModel.proposals.map(\.id), [16, 12, 9, 13])
        XCTAssertEqual(viewModel.departmentTitle, "NativeOps")

        viewModel.status = .reviewing
        XCTAssertEqual(viewModel.proposals.map(\.id), [16, 12])
        XCTAssertEqual(viewModel.statusTitle, "검토 중")
    }

    // MARK: 12-2b 운영 제안 상세

    func testDetailMatchesFigma() async throws {
        let viewModel = makeContainer().makeProposalDetailViewModel(proposalId: 16)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertTrue(detail.metaText.hasSuffix("조회 128"), "볼 때마다 조회 수 +1")
        XCTAssertEqual(detail.stepDates.map(\.status), [.received, .reviewing, .inProgress, .completed])
        XCTAssertEqual(detail.stepDates.map { $0.date != nil }, [true, true, false, false])
        XCTAssertEqual(detail.answer?.department, "NativeOps")
        XCTAssertEqual(detail.comments.count, 7)
        XCTAssertTrue(detail.comments.first?.headerText.hasPrefix("익명 · ") == true)
        XCTAssertTrue(detail.comments.dropFirst().first?.headerText.hasPrefix("이시우 · ") == true)
    }

    func testRecommendToggle() async {
        let viewModel = makeContainer().makeProposalDetailViewModel(proposalId: 16)
        await viewModel.load()
        XCTAssertTrue(viewModel.recommendNote.hasPrefix("1인 1회"))

        await viewModel.toggleRecommend()
        XCTAssertEqual(viewModel.detail?.isRecommended, true)
        XCTAssertEqual(viewModel.detail?.proposal.recommendCount, 33)
        XCTAssertTrue(viewModel.recommendNote.contains("현재 33"))

        await viewModel.toggleRecommend()
        XCTAssertEqual(viewModel.detail?.isRecommended, false)
        XCTAssertEqual(viewModel.detail?.proposal.recommendCount, 32)
    }

    func testCommentOnMyProposal() async throws {
        let container = makeContainer()
        let viewModel = container.makeProposalDetailViewModel(proposalId: 12)
        await viewModel.load()
        XCTAssertFalse(viewModel.canSendComment)

        viewModel.commentText = "  캘린더 연동도 같이 보면 좋겠어요  "
        await viewModel.sendComment()
        let last = try XCTUnwrap(viewModel.detail?.comments.last)
        XCTAssertEqual(last.body, "캘린더 연동도 같이 보면 좋겠어요")
        XCTAssertTrue(last.headerText.hasPrefix("옥물결 · 제안자 · "))
        XCTAssertEqual(viewModel.commentText, "")

        let list = container.makeProposalListViewModel()
        await list.load()
        XCTAssertEqual(list.proposals.first { $0.id == 12 }?.commentCount, 3)
    }
}
