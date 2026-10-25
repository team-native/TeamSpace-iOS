import XCTest
@testable import TeamSpace

@MainActor
final class NotificationStateTests: XCTestCase {
    private func makeViewModel() -> NotificationCenterViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeNotificationCenterViewModel()
    }

    // MARK: 02-4 규칙 필터

    func testRuleFilterShowsUnreadAndReadCount() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.filter = .rule

        let summary = viewModel.readSummary(for: .rule)
        XCTAssertEqual(summary.unread, 1)
        XCTAssertEqual(summary.read, 1)
        let items = viewModel.sections().flatMap(\.items)
        XCTAssertTrue(items.allSatisfy { $0.type == .rule })
        XCTAssertNotNil(items.first?.effectiveAt, "규칙 알림은 시행일을 함께 받아요")
    }

    // MARK: 02-3 문의 답변

    func testInquiryAnswerBelongsToPersonalTask() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.filter = .personalTask

        let types = viewModel.sections().flatMap(\.items).map(\.type)
        XCTAssertTrue(types.contains(.inquiryAnswer))
    }

    // MARK: 02-5 모두 확인

    func testAllCaughtUpAfterMarkAllAsRead() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        XCTAssertFalse(viewModel.isAllCaughtUp)

        await viewModel.markAllAsRead()

        XCTAssertTrue(viewModel.isAllCaughtUp)
        XCTAssertEqual(viewModel.readSummary(for: .all).unread, 0)
    }

    // MARK: 02-8 알림 진입

    func testNotificationEntryFromPushPayload() {
        XCTAssertNil(NotificationEntry(type: nil, deepLink: "/approvals/12"))
        XCTAssertEqual(NotificationEntry(type: "APPROVAL", deepLink: nil)?.type, .approval)
        XCTAssertEqual(NotificationEntry(type: "NEW_TYPE", deepLink: nil)?.type, .unknown)
    }

    func testEntryRouterIsUsedOnlyOnce() throws {
        let router = NotificationEntryRouter()
        let entry = try XCTUnwrap(NotificationEntry(type: "RULE", deepLink: "/rules/3"))

        router.receive(entry)
        XCTAssertEqual(router.take(), entry)
        XCTAssertNil(router.take(), "한 번 이동하면 다시 이동하지 않아요")

        router.receive(entry)
        router.cancel()
        XCTAssertNil(router.pending)
    }
}
