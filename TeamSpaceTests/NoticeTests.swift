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

    func testNoticeListLoadsMorePages() async throws {
        let store = MockNoticeStore()
        let first = try JSONCoder.makeDecoder().decode(
            CursorPageDTO<ServerNoticeItemDTO>.self, from: Data(store.serverItemsJSON(limit: 2).utf8)
        )
        XCTAssertEqual(first.items.map(\.id), [1, 41])
        XCTAssertEqual(first.nextCursor, "o:2")
        let last = try JSONCoder.makeDecoder().decode(
            CursorPageDTO<ServerNoticeItemDTO>.self, from: Data(store.serverItemsJSON(cursor: "o:4", limit: 2).utf8)
        )
        XCTAssertEqual(last.items.map(\.id), [5])
        XCTAssertNil(last.nextCursor)

        let viewModel = makeContainer().makeNoticeListViewModel(user: member)
        await viewModel.load()
        XCTAssertFalse(viewModel.paging.hasMore, "5건이면 한 페이지에 다 와요")
        await viewModel.loadMore()
        XCTAssertEqual(viewModel.notices.count, 5, "더 없으면 그대로")
    }

    // MARK: 10-6 공지 상세

    func testNoticeDetailAndAcknowledge() async throws {
        let container = makeContainer()
        let viewModel = container.makeNoticeDetailViewModel(noticeId: 41)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertEqual(detail.authorText, "김민준", "서버는 작성자 이름만 줘요")
        XCTAssertFalse(detail.metaText.contains("조회"), "서버는 조회 수를 주지 않아요")
        XCTAssertTrue(detail.notice.isImportant, "필독")
        XCTAssertEqual(detail.notice.category, .finance)
        XCTAssertNil(detail.linkedDocument)
        XCTAssertEqual(detail.acknowledgeTitle, "확인했어요")

        await viewModel.acknowledge()
        XCTAssertTrue(viewModel.didAcknowledge)
        XCTAssertTrue(viewModel.isAcknowledged)
        XCTAssertTrue(viewModel.detail?.acknowledgeTitle.hasSuffix(" 확인 완료") == true, "방금 확인하면 날짜도 보여요")

        let again = container.makeNoticeDetailViewModel(noticeId: 41)
        await again.load()
        XCTAssertEqual(again.detail?.acknowledgeTitle, "확인 완료", "다시 열면 서버 confirmedByMe 로 확인 상태만 알아요")
    }

    func testServerNoticeDetailDecoding() throws {
        let json = #"{"id":"7","kind":"재무","title":"정산 안내","body":"본문","author":"김민준","createdAt":"2026-10-20T09:30:00.123456","pinned":true,"mustRead":true,"confirmed":3,"total":24,"confirmedByMe":true,"audience":"NATIVE"}"#
        let dto = try JSONCoder.makeDecoder().decode(ServerNoticeItemDTO.self, from: Data(json.utf8))
        let detail = dto.toDetail()

        XCTAssertEqual(detail.notice.id, 7, "문자열 id")
        XCTAssertEqual(detail.notice.category, .finance)
        XCTAssertTrue(detail.notice.isPinned)
        XCTAssertTrue(detail.isAcknowledged)
        XCTAssertEqual(detail.acknowledgeTitle, "확인 완료")
        XCTAssertEqual(dto.confirmed, 3)
        XCTAssertEqual(dto.total, 24)
        XCTAssertEqual(detail.notice.updatedAt, ServerDate.parse("2026-10-20T09:30:00.123Z"), "시간대 없으면 UTC")
    }

    func testLinkedDocumentRoutes() {
        XCTAssertEqual(NoticeLinkedDocument(id: 1, title: "프로젝트 운영 원칙", category: .rule).route, .ruleDetail(id: 1))
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

        let empty = container.makeNoticeComposeViewModel(user: fa)
        empty.draft.title = "작성 중"
        await empty.saveDraft()
        XCTAssertEqual(empty.errorMessage, "body 항목은 필수입니다.", "서버는 임시 저장도 본문이 있어야 받아요")

        let draft = container.makeNoticeComposeViewModel(user: fa)
        draft.draft.title = "작성 중"
        draft.draft.body = "아직 쓰는 중이에요."
        await draft.saveDraft()
        XCTAssertEqual(draft.completionMessage, "공지를 임시 저장했어요.")

        let list = container.makeNoticeListViewModel(user: fa)
        await list.load()
        XCTAssertFalse(list.notices.contains { $0.title == "예약 공지" || $0.title == "작성 중" })
    }

    func testPublishSendsServerShapeWithUploadedAttachments() async throws {
        let tokenStorage = InMemoryTokenStorage()
        let transport = MockTransport(latencyNanoseconds: 0)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: transport, tokenStorage: tokenStorage)
        let repository = NoticeRepositoryImpl(client: client)
        var draft = NoticeDraft(scheduledAt: Date().addingTimeInterval(86_400))
        draft.title = "예약 공지"
        draft.body = "내일 올라가요."
        draft.isPinned = false
        draft.timing = .scheduled
        draft.sendsPush = false
        draft.attachments = [NoticeAttachment(fileName: "안내.pdf", data: Data("%PDF-1.4".utf8))]

        let summary = try await repository.publish(draft, asDraft: false)

        let sent = try XCTUnwrap(transport.boardStore.noticeStore.lastCreateRequest)
        XCTAssertEqual(sent.kind, "공지")
        XCTAssertEqual(sent.status, .scheduled)
        XCTAssertNotNil(sent.publishAt)
        XCTAssertFalse(sent.pinned)
        XCTAssertTrue(sent.mustRead)
        XCTAssertFalse(sent.sendPush)
        XCTAssertEqual(sent.attachments.count, 1, "첨부는 /uploads 로 먼저 올린 id 로 보내요")
        XCTAssertEqual(summary.title, "예약 공지")
        XCTAssertEqual(NoticeRepositoryImpl.mimeType(of: "안내.pdf"), "application/pdf")
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
