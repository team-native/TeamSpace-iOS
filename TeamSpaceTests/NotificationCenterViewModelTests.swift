import XCTest
@testable import TeamSpace

@MainActor
final class NotificationCenterViewModelTests: XCTestCase {
    private func makeViewModel() -> NotificationCenterViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeNotificationCenterViewModel()
    }

    func testLoadGroupsTodayAndThisWeek() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        let sections = viewModel.sections()
        XCTAssertEqual(sections.first?.title, "오늘")
        XCTAssertTrue(sections.map(\.title).contains("이번 주"))
        XCTAssertEqual(viewModel.unreadCount(for: .all), 5)
        XCTAssertEqual(viewModel.unreadCount(for: .personalTask), 2, "결재 요청 + 문의 답변")
        XCTAssertEqual(viewModel.unreadCount(for: .rule), 1)
        XCTAssertNil(viewModel.unreadCount(for: .notice), "안 읽은 공지가 없으면 숫자를 숨겨요")
    }

    func testFilterShowsOnlyMatchingType() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.filter = .finance

        let items = viewModel.sections().flatMap(\.items)
        XCTAssertEqual(items.map(\.type), [.finance])
    }

    func testMarkAllAsRead() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        await viewModel.markAllAsRead()

        XCTAssertFalse(viewModel.hasUnread)
        XCTAssertNil(viewModel.toastMessage)
    }

    func testMarkAllAsReadIsSavedOnServer() async {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let container = DIContainer(apiClient: client, tokenStorage: tokenStorage)
        let viewModel = container.makeNotificationCenterViewModel()
        await viewModel.load()

        await viewModel.markAllAsRead()

        let reloaded = container.makeNotificationCenterViewModel()
        await reloaded.load()
        XCTAssertFalse(reloaded.hasUnread, "{ all: true } 로 서버에 저장돼요")
    }

    func testMarkOneAsReadIsSavedOnServer() async throws {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let container = DIContainer(apiClient: client, tokenStorage: tokenStorage)
        let viewModel = container.makeNotificationCenterViewModel()
        await viewModel.load()
        let first = try XCTUnwrap(viewModel.sections().flatMap(\.items).first { !$0.isRead })

        await viewModel.markAsRead(first)

        let reloaded = container.makeNotificationCenterViewModel()
        await reloaded.load()
        XCTAssertEqual(reloaded.unreadCount(for: .all), 4)
        XCTAssertNil(viewModel.toastMessage)
    }

    func testNotificationDecodingFromServer() throws {
        let json = #"""
        {"code":200,"message":"조회 성공","data":{"items":[
         {"id":"12","kind":"내 업무","sourceKind":"내 업무","title":"결재 요청","createdAt":"2026-10-01T10:00:00+00:00",
          "href":"/inhouse/requests/7","unread":true,"action":true},
         {"id":"11","kind":"내 업무","sourceKind":"내 업무","title":"문의 답변","createdAt":"2026-10-01T09:00:00+00:00",
          "href":"/inhouse/community/inquiry?id=42","unread":false,"action":false},
         {"id":"10","kind":"공지","sourceKind":"게시판","title":"새 댓글","createdAt":"2026-10-01T08:00:00+00:00",
          "href":"/inhouse/community/notices/3","unread":true,"action":false},
         {"id":"9","kind":"공지","sourceKind":"공지","title":"규칙 개정","createdAt":"2026-10-01T07:00:00+00:00",
          "href":"/inhouse/documents/finance-pool","unread":true,"action":false},
         {"id":"8","kind":"재정","sourceKind":"재정","title":"입금","createdAt":"2026-10-01T06:00:00+00:00",
          "href":"/inhouse/finance/receipts","unread":true,"action":true}
        ],"nextCursor":"8"}}
        """#
        let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<NotificationListResponseDTO>.self, from: Data(json.utf8))
        let page = try XCTUnwrap(envelope.data).toEntity()
        XCTAssertEqual(page.items.map(\.id), [12, 11, 10, 9, 8])
        XCTAssertEqual(page.items.map(\.type), [.approval, .inquiryAnswer, .notice, .rule, .finance])
        XCTAssertEqual(page.items.map(\.isRead), [false, true, false, false, false])
        XCTAssertEqual(page.items.map(\.deepLink), [
            "/approvals/7", "/inquiries/42", "/notices/3", "/rules/finance-pool", "/finance/receipts"
        ])
        XCTAssertEqual(page.items[1].type.targetRoute(deepLink: page.items[1].deepLink), .inquiryDetail(id: 42))
        XCTAssertEqual(page.items[3].type.targetRoute(deepLink: page.items[3].deepLink), .ruleDetail(id: "finance-pool"))
        XCTAssertNil(page.items[0].message, "서버에 본문이 없어요")
        XCTAssertEqual(page.nextCursor, "8")
    }

    func testNotificationReadRequestBody() throws {
        let one = try JSONEncoder().encode(NotificationReadRequestDTO(id: "12", all: false))
        let all = try JSONEncoder().encode(NotificationReadRequestDTO(id: nil, all: true))
        XCTAssertEqual(String(decoding: one, as: UTF8.self), #"{"id":"12"}"#)
        XCTAssertEqual(String(decoding: all, as: UTF8.self), #"{"all":true}"#)
    }

    func testNotificationListDecodingFromSpecExample() throws {
        let json = #"""
        {"code":200,"message":"조회 성공","data":{"list":[{"id":101,"type":"APPROVAL","title":"새 결재 요청",
         "deepLink":"/approvals/12","isRead":false,"createdAt":"2026-10-01T10:00:00Z"},
         {"id":102,"type":"SOMETHING_NEW","title":"새 종류","deepLink":"/x","isRead":true,"createdAt":"2026-10-01T09:00:00Z"}]}}
        """#
        let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<NotificationListResponseDTO>.self, from: Data(json.utf8))
        let list = try XCTUnwrap(envelope.data).items.map { $0.toEntity() }
        XCTAssertEqual(list.map(\.type), [.approval, .unknown])
        XCTAssertNil(list[0].message, "명세서에 없는 message 는 없어도 디코딩돼요")
    }

    // MARK: COMMON-02 목록 페이지네이션

    func testNotificationPageDecodingFromServer() throws {
        let json = #"""
        {"code":200,"message":"조회 성공","data":{"items":[{"id":101,"type":"APPROVAL","title":"새 결재 요청",
         "isRead":false,"createdAt":"2026-10-01T10:00:00Z"}],"nextCursor":"101"}}
        """#
        let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<NotificationListResponseDTO>.self, from: Data(json.utf8))
        let page = try XCTUnwrap(envelope.data).toEntity()
        XCTAssertEqual(page.items.map(\.id), [101])
        XCTAssertEqual(page.nextCursor, "101")
        XCTAssertTrue(page.hasMore)
    }

    func testLoadMoreAppendsNextPages() async {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let container = DIContainer(apiClient: client, tokenStorage: tokenStorage)
        let viewModel = NotificationCenterViewModel(
            fetchNotificationsUseCase: FetchNotificationsUseCase(
                notificationRepository: NotificationRepositoryImpl(client: client),
                pageSize: 3
            ),
            markNotificationsReadUseCase: container.markNotificationsReadUseCase
        )

        await viewModel.load()
        XCTAssertEqual(viewModel.sections().flatMap(\.items).count, 3)
        XCTAssertTrue(viewModel.paging.hasMore)

        await viewModel.loadMore()
        await viewModel.loadMore()
        let all = viewModel.sections().flatMap(\.items)
        XCTAssertEqual(all.count, 8, "3 + 3 + 2")
        XCTAssertEqual(Set(all.map(\.id)).count, 8, "겹치는 알림 없이")
        XCTAssertEqual(all.map(\.createdAt), all.map(\.createdAt).sorted(by: >), "붙인 뒤에도 최신순")
        XCTAssertFalse(viewModel.paging.hasMore, "마지막 페이지면 더 부르지 않아요")

        await viewModel.loadMore()
        XCTAssertEqual(viewModel.sections().flatMap(\.items).count, 8)
    }
}
