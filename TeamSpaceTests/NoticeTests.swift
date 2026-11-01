import XCTest
@testable import TeamSpace

@MainActor
final class NoticeTests: XCTestCase {
    private let member = AuthUser(id: 1, name: "옥물결", roles: [.member])
    private let fa = AuthUser(id: 2, name: "김민준", roles: [.fa])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 10-5 공지 목록

    func testNoticeListPinnedFirstAndFilters() async {
        let container = makeContainer()
        let viewModel = container.makeNoticeListViewModel(user: member)
        await viewModel.load()

        XCTAssertFalse(viewModel.canPublish, "일반 구성원은 공지 작성 버튼이 없어요")
        XCTAssertTrue(container.makeNoticeListViewModel(user: fa).canPublish)
        XCTAssertEqual(viewModel.notices.map(\.id), [1, 41, 42, 43, 5], "고정 → 최신순")
        XCTAssertTrue(viewModel.notices.first?.dateText().hasPrefix("고정 · ") == true)
        XCTAssertEqual(viewModel.notices.dropFirst().first?.dateText(), "어제")

        viewModel.filter = .category(.finance)
        XCTAssertEqual(viewModel.notices.map(\.title), ["10월 프로젝트 정산 기준 안내"])
        viewModel.filter = .category(.rule)
        XCTAssertEqual(viewModel.notices.map(\.id), [42])
    }

    // MARK: 10-6 공지 상세

    func testNoticeDetailAndAcknowledge() async throws {
        let container = makeContainer()
        let viewModel = container.makeNoticeDetailViewModel(noticeId: 41)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertEqual(detail.authorText, "김민준 · FA")
        XCTAssertTrue(detail.metaText.hasSuffix("조회 53"), "볼 때마다 조회 수 +1")
        XCTAssertTrue(detail.notice.isImportant, "필독")
        XCTAssertEqual(detail.linkedDocument?.caption, "문서함 · FINANCE")
        XCTAssertEqual(detail.acknowledgeTitle, "확인했어요")

        await viewModel.acknowledge()
        XCTAssertTrue(viewModel.didAcknowledge)
        XCTAssertTrue(viewModel.isAcknowledged)

        let again = container.makeNoticeDetailViewModel(noticeId: 41)
        await again.load()
        XCTAssertTrue(again.detail?.acknowledgeTitle.hasSuffix("확인 완료") == true)
    }

    func testLinkedRuleOpensRuleDetail() async throws {
        let viewModel = makeContainer().makeNoticeDetailViewModel(noticeId: 42)
        await viewModel.load()
        XCTAssertEqual(viewModel.detail?.linkedDocument?.route, .ruleDetail(id: 1))
    }

    // MARK: 10-7 전체 공지 작성

    func testPublishNowAppearsFirst() async {
        let container = makeContainer()
        let compose = container.makeNoticeComposeViewModel(user: fa)
        XCTAssertFalse(compose.canPublish)
        XCTAssertEqual(compose.draft.checklist, [
            "대상: Native 전체", "중요 표시·상단 고정 사용", "지금 바로 게시", "전체 공지 카테고리로 알림 생성"
        ])
        XCTAssertEqual(compose.draft.publishTitle, "대상 확인 · 지금 게시")

        compose.draft.title = "11월 워크숍 안내"
        compose.draft.body = "11월 워크숍 일정을 안내해요."
        await compose.publish()
        XCTAssertEqual(compose.completionMessage, "공지를 게시했어요.")

        let list = container.makeNoticeListViewModel(user: fa)
        await list.load()
        XCTAssertEqual(list.notices.first?.title, "11월 워크숍 안내")
    }

    func testScheduledAndDraftAreHiddenFromList() async {
        let container = makeContainer()
        let compose = container.makeNoticeComposeViewModel(user: fa)
        compose.draft.title = "예약 공지"
        compose.draft.body = "내일 올라가요."
        compose.draft.timing = .scheduled
        compose.draft.sendsPush = false
        XCTAssertEqual(compose.draft.publishTitle, "대상 확인 · 예약 게시 확정")
        XCTAssertTrue(compose.draft.checklist.contains { $0.hasSuffix("09:00 예약 게시") })
        XCTAssertEqual(compose.draft.checklist.last, "알림 없이 게시")

        await compose.publish()
        XCTAssertTrue(compose.completionMessage?.hasSuffix("09:00에 예약 게시돼요.") == true)

        let draft = container.makeNoticeComposeViewModel(user: fa)
        draft.draft.title = "작성 중"
        await draft.saveDraft()
        XCTAssertEqual(draft.completionMessage, "공지를 임시 저장했어요.")

        let list = container.makeNoticeListViewModel(user: fa)
        await list.load()
        XCTAssertFalse(list.notices.contains { $0.title == "예약 공지" || $0.title == "작성 중" })
    }

    func testPublishRules() async {
        let container = makeContainer()
        let byMember = container.makeNoticeComposeViewModel(user: member)
        byMember.draft.title = "제목"
        byMember.draft.body = "본문"
        await byMember.publish()
        XCTAssertNotNil(byMember.errorMessage, "권한이 없으면 게시할 수 없어요")
        XCTAssertNil(byMember.completionMessage)

        let past = container.makeNoticeComposeViewModel(user: fa)
        past.draft.title = "제목"
        past.draft.body = "본문"
        past.draft.timing = .scheduled
        past.draft.scheduledAt = Date().addingTimeInterval(-3_600)
        await past.publish()
        XCTAssertNotNil(past.errorMessage, "예약 일시는 지금보다 뒤")
    }

    // MARK: 연결

    func testNoticeNotificationRoutes() {
        XCTAssertEqual(NotificationType.notice.targetRoute(deepLink: "/notices/1"), .noticeDetail(id: 1), "02-2 공지 알림 → 10-6")
        XCTAssertEqual(NotificationType.notice.targetRoute(deepLink: nil), .notices)
    }
}
