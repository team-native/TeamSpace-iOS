import XCTest
@testable import TeamSpace

@MainActor
final class BoardTests: XCTestCase {
    private func makeContainer(defaultsName: String = #function) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let defaults = UserDefaults(suiteName: "test.board.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsRecentSearchRepository.boardKey)
        defaults.removeObject(forKey: UserDefaultsPostDraftRepository.key)
        return DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            boardRecentSearchRepository: UserDefaultsRecentSearchRepository(
                defaults: defaults,
                key: UserDefaultsRecentSearchRepository.boardKey,
                seed: MockBoardStore.recentKeywords
            ),
            postDraftRepository: UserDefaultsPostDraftRepository(defaults: defaults)
        )
    }

    // MARK: 10-1 팀 게시판

    func testBoardShowsThisWeekLatestFirst() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.period, .week)
        XCTAssertEqual(Array(viewModel.posts.map(\.id).prefix(9)), [41, 40, 31, 39, 36, 35, 28, 37, 34], "최근 7일 · 최신순")
        XCTAssertFalse(viewModel.posts.contains { $0.id == 22 }, "12일 전 글은 이번 주가 아니에요")
        XCTAssertEqual(viewModel.pinnedNotices.map(\.title), ["10월 프로젝트 정산 기준 안내", "외주 프로젝트 착수 전 체크리스트"])
        XCTAssertEqual(viewModel.posts.first?.authorText, "익명")
        XCTAssertEqual(viewModel.posts.dropFirst().first?.authorText, "김민준", "서버는 작성자 역할을 주지 않아요")
        XCTAssertEqual(viewModel.posts.first?.category, .question, "서버 분류 \"질문\"")
        XCTAssertTrue(viewModel.posts.first { $0.id == 36 }?.hasImage == true, "첨부가 있으면 사진 표시")
        XCTAssertEqual(viewModel.inquiryCount, 2)
        XCTAssertEqual(viewModel.board?.myRecord?.proposalCount, 3)
        XCTAssertFalse(viewModel.paging.hasMore)
    }

    func testBoardFiltersAndSortAskServerAgain() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        viewModel.selectFilter(.category(.question))
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.posts.map(\.id), [41, 39, 28, 34])
        XCTAssertTrue(viewModel.pinnedNotices.isEmpty, "분류를 고르면 고정 공지는 숨겨요")

        viewModel.selectFilter(.notice)
        await viewModel.waitForReload()
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.pinnedNotices.count, 2)
        XCTAssertNil(viewModel.emptyMessage)

        viewModel.selectFilter(.all)
        viewModel.selectPeriod(.today)
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.posts.map(\.id), [41, 40])

        viewModel.selectPeriod(.all)
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.posts.count, 14)
        viewModel.selectSort(.popular)
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.posts.first?.id, 36, "추천 33")
    }

    func testPopularPostsAndShowMore() async {
        let viewModel = makeContainer().makeBoardViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.popularPosts.map(\.id), [36, 35, 37], "이번 주 추천 많은 순 3개")
        XCTAssertEqual(viewModel.popularPosts.first?.reactionText, "익명 · 추천 33 · 댓글 9")

        viewModel.selectFilter(.category(.info))
        viewModel.selectPeriod(.today)
        viewModel.showPopular()
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.filter, .all)
        XCTAssertEqual(viewModel.period, .week)
        XCTAssertEqual(viewModel.posts.prefix(3).map(\.id), [36, 35, 37])
    }

    func testPostsLoadNextPageWithServerCursor() async {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        let container = DIContainer(apiClient: client, tokenStorage: tokenStorage)
        let viewModel = BoardViewModel(
            fetchBoardUseCase: container.fetchBoardUseCase,
            fetchPostsUseCase: FetchPostsUseCase(boardRepository: BoardRepositoryImpl(client: client), pageSize: 5)
        )
        viewModel.selectPeriod(.all)
        await viewModel.waitForReload()
        XCTAssertEqual(viewModel.posts.count, 5)
        XCTAssertEqual(viewModel.paging.nextCursor, "o:5")

        await viewModel.loadMore()
        await viewModel.loadMore()
        XCTAssertEqual(viewModel.posts.count, 14)
        XCTAssertFalse(viewModel.paging.hasMore)
        XCTAssertEqual(Set(viewModel.posts.map(\.id)).count, 14, "겹치는 글 없이 이어 붙여요")
    }

    func testPostQueryUsesServerParameters() {
        var query = PostListQuery(category: .info, period: .week, sort: .likes)
        let items = Dictionary(uniqueKeysWithValues: query.queryItems(cursor: "o:20", limit: 20).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items, ["category": "정보 공유", "period": "week", "sort": "likes", "cursor": "o:20", "limit": "20"])

        let from = ISO8601DateFormatter().date(from: "2026-10-01T03:00:00Z") ?? Date()
        let to = ISO8601DateFormatter().date(from: "2026-10-05T03:00:00Z") ?? Date()
        query.period = .range(from: to, to: from)
        let range = Dictionary(uniqueKeysWithValues: query.queryItems(cursor: nil, limit: 20).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(range["from"], "2026-10-01")
        XCTAssertEqual(range["to"], "2026-10-05")
        XCTAssertEqual(range["period"], "all")
    }

    func testServerPostItemDecodesPythonDatesAndStringIds() throws {
        let json = #"""
        {"items":[{"id":"7","category":"정보공유","title":"t","body":"첫 줄\n둘째 줄","anonymous":false,"anonComments":false,
          "views":3,"likes":2,"createdAt":"2026-11-02T01:20:00.123456+00:00","when":"2026-11-02T01:20:00.123456+00:00",
          "pinned":false,"mine":true,"commentCount":1,"attachments":["upload-1",{"id":"2"}],"author":"안율"}],
         "nextCursor":"o:20"}
        """#
        let page = try JSONCoder.makeDecoder().decode(CursorPageDTO<ServerPostItemDTO>.self, from: Data(json.utf8))
        let post = try XCTUnwrap(page.items.first?.toEntity())
        XCTAssertEqual(post.id, 7)
        XCTAssertEqual(post.category, .info)
        XCTAssertEqual(post.excerpt, "첫 줄 둘째 줄")
        XCTAssertEqual(post.authorName, "안율")
        XCTAssertTrue(post.isMine)
        XCTAssertTrue(post.hasImage)
        XCTAssertEqual(post.createdAt.timeIntervalSince1970, 1_793_582_400.123, accuracy: 0.001)
        XCTAssertNotNil(ServerDate.parse("2026-11-02T01:20:00"), "시간대가 없으면 UTC")
        XCTAssertNotNil(ServerDate.parse("2026-11-02T10:20:00+09:00"))
    }

    func testCustomPeriodIncludesWholeDays() {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.startOfDay(for: now).addingTimeInterval(-3 * 86_400)
        let period = BoardPeriod.custom(start: start.addingTimeInterval(3_600), end: start)

        XCTAssertTrue(period.contains(start, now: now), "시작일 0시")
        XCTAssertTrue(period.contains(start.addingTimeInterval(86_399), now: now), "종료일 23:59")
        XCTAssertFalse(period.contains(start.addingTimeInterval(86_400), now: now))
        XCTAssertEqual(BoardPeriod.week.title, "이번 주")
    }

    // MARK: 10-12 게시글 검색

    func testSearchFindsNoticeAndPosts() async {
        let viewModel = makeContainer().makeBoardSearchViewModel()
        XCTAssertEqual(viewModel.recentKeywords, MockBoardStore.recentKeywords)

        viewModel.query = "정산"
        await viewModel.search()

        XCTAssertEqual(viewModel.resultTitle, "정산 검색 결과 4건")
        XCTAssertEqual(viewModel.result.notices.map(\.title), ["10월 프로젝트 정산 기준 안내"])
        XCTAssertEqual(viewModel.result.posts.map(\.title), [
            "정산 내역 공개 범위 제안드려요", "외주 정산 서류 어디까지 챙기나요?", "9월 정산 후기와 개선점"
        ])
        XCTAssertTrue(viewModel.result.posts.first?.searchMetaText().hasPrefix("팀 게시판 · 익명 · ") == true)
    }

    func testSearchEmptyAndRecentKeywords() async {
        let viewModel = makeContainer().makeBoardSearchViewModel()

        viewModel.query = "없는검색어"
        await viewModel.search()
        guard case .empty = viewModel.state else { return XCTFail("결과가 없으면 empty") }

        viewModel.submit()
        XCTAssertEqual(viewModel.recentKeywords.first, "없는검색어")
        viewModel.removeRecent("없는검색어")
        XCTAssertEqual(viewModel.recentKeywords, MockBoardStore.recentKeywords)

        viewModel.clearRecent()
        viewModel.query = ""
        XCTAssertTrue(viewModel.recentKeywords.isEmpty)
        XCTAssertFalse(viewModel.showsRecent)
    }

    // MARK: 연결

    // MARK: 10-3 게시글 상세

    func testPostDetailMatchesFigma() async throws {
        let viewModel = makeContainer().makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertEqual(detail.post.title, "게임에 대해서 어떻게 생각하시나요")
        XCTAssertTrue(detail.body.hasSuffix("게임중독 탈출 방안 없을까요"))
        XCTAssertEqual(detail.post.viewCount, 49, "볼 때마다 조회 수 +1")
        XCTAssertEqual(detail.policyText, "이 글은 익명 댓글로 운영돼요.")
        XCTAssertEqual(detail.commentButtonTitle, "익명으로 댓글 남기기")
        XCTAssertEqual(detail.comments.map(\.authorText), ["익명", "익명 · 글쓴이"], "서버는 익명 번호 없이 글쓴이만 알려줘요")
        XCTAssertTrue(viewModel.canReport)
        XCTAssertFalse(viewModel.canDelete)

        viewModel.didCopyLink()
        XCTAssertEqual(viewModel.link, "teamspace://posts/41")
        XCTAssertEqual(viewModel.toastMessage, "링크를 복사했어요")
    }

    /// 10-3b 댓글 공감 — 누르면 빨간 하트 · +1, 다시 누르면 원래대로. 다시 불러와도 수가 남아요.
    // MARK: 내 글 수정 (PATCH /posts/{id})

    func testEditMyPostPrefillsAndUpdates() async throws {
        let container = makeContainer()
        let detailViewModel = container.makePostDetailViewModel(postId: 31)
        await detailViewModel.load()
        let detail = try XCTUnwrap(detailViewModel.detail)
        XCTAssertTrue(detailViewModel.canEdit)

        let compose = container.makePostComposeViewModel(editing: detail)
        XCTAssertTrue(compose.isEditing)
        XCTAssertFalse(compose.didRestoreDraft)
        XCTAssertEqual(compose.draft.title, detail.post.title)
        XCTAssertEqual(compose.draft.body, detail.body)
        XCTAssertEqual(compose.draft.isAnonymous, detail.post.isAnonymous)
        XCTAssertEqual(compose.publishTitle, "수정 완료")
        XCTAssertEqual(compose.screenTitle, "글 수정")

        compose.draft.title = "  고친 제목  "
        compose.draft.body = "고친 본문이에요."
        compose.draft.category = .question
        await compose.publish()
        XCTAssertTrue(compose.didUpdate)
        XCTAssertNil(compose.errorMessage)
        XCTAssertNil(compose.publishedPost, "새 글 완료 알림은 띄우지 않아요")

        await detailViewModel.load()
        XCTAssertEqual(detailViewModel.detail?.post.title, "고친 제목")
        XCTAssertEqual(detailViewModel.detail?.body, "고친 본문이에요.")
        XCTAssertEqual(detailViewModel.detail?.post.category, .question)
        XCTAssertEqual(detailViewModel.detail?.post.likeCount, detail.post.likeCount, "공감 수는 그대로")
    }

    func testEditKeepsSavedDraftUntouched() async throws {
        let container = makeContainer()
        let newPost = container.makePostComposeViewModel()
        newPost.draft.title = "임시 글"
        XCTAssertTrue(newPost.saveDraft())

        let detailViewModel = container.makePostDetailViewModel(postId: 28)
        await detailViewModel.load()
        let compose = container.makePostComposeViewModel(editing: try XCTUnwrap(detailViewModel.detail))
        XCTAssertNotEqual(compose.draft.title, "임시 글", "수정은 임시 저장을 불러오지 않아요")
        await compose.publish()
        XCTAssertTrue(compose.didUpdate)
        XCTAssertEqual(container.makePostComposeViewModel().draft.title, "임시 글", "임시 저장은 남아 있어요")
    }

    func testCannotEditOthersPost() async throws {
        let container = makeContainer()
        let detailViewModel = container.makePostDetailViewModel(postId: 41)
        await detailViewModel.load()
        let detail = try XCTUnwrap(detailViewModel.detail)
        XCTAssertFalse(detailViewModel.canEdit)

        let compose = container.makePostComposeViewModel(editing: detail)
        await compose.publish()
        XCTAssertFalse(compose.didUpdate)
        XCTAssertEqual(compose.errorMessage, "작성자만 게시글을 수정할 수 있습니다.")
    }

    func testEditRejectsEmptyTitle() async throws {
        let container = makeContainer()
        let detailViewModel = container.makePostDetailViewModel(postId: 31)
        await detailViewModel.load()
        let compose = container.makePostComposeViewModel(editing: try XCTUnwrap(detailViewModel.detail))
        compose.draft.title = "   "
        XCTAssertFalse(compose.canPublish)
        await compose.publish()
        XCTAssertFalse(compose.didUpdate)
    }

    func testPostPatchBodyOmitsAttachments() throws {
        let dto = ServerPostPatchRequestDTO(category: "질문", title: "t", body: "b", anonymous: true, anonComments: false)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["category", "title", "body", "anonymous", "anonComments"])
    }

    func testCommentLikeToggles() async throws {
        let container = makeContainer()
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let comment = try XCTUnwrap(viewModel.detail?.comments.first)
        XCTAssertEqual(comment.likeCount, 0)
        XCTAssertFalse(comment.isLiked)

        await viewModel.toggleCommentLike(comment.id)
        let liked = try XCTUnwrap(viewModel.detail?.comments.first)
        XCTAssertTrue(liked.isLiked)
        XCTAssertEqual(liked.likeCount, 1)
        XCTAssertEqual(viewModel.detail?.comments.last?.likeCount, 0, "다른 댓글은 그대로")
        XCTAssertTrue(viewModel.likingCommentIds.isEmpty)

        await viewModel.load()
        XCTAssertEqual(viewModel.detail?.comments.first?.likeCount, 1, "서버 likes 를 읽어요")

        await viewModel.toggleCommentLike(comment.id)
        XCTAssertEqual(viewModel.detail?.comments.first?.isLiked, false)
        XCTAssertEqual(viewModel.detail?.comments.first?.likeCount, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCommentLikeUnknownCommentShowsError() async throws {
        let viewModel = makeContainer().makePostDetailViewModel(postId: 41)
        await viewModel.load()

        await viewModel.toggleCommentLike(999_999)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.detail?.comments.allSatisfy { !$0.isLiked } ?? false)
    }

    func testServerCommentLikesDecoding() throws {
        let json = Data(#"""
        {"id":"7","postId":"41","anonymous":true,"text":"hi","createdAt":"2026-11-02T09:00:00.123456+09:00","likes":4,"mine":false}
        """#.utf8)
        let decoder = JSONCoder.makeDecoder()
        let comment = try decoder.decode(ServerCommentDTO.self, from: json).toEntity(postAuthor: nil)
        XCTAssertEqual(comment.likeCount, 4)
        XCTAssertFalse(comment.isLiked, "서버가 liked 를 안 주면 빈 하트")
    }

    func testRealNamePostComments() async throws {
        let viewModel = makeContainer().makePostDetailViewModel(postId: 40)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertEqual(detail.commentPolicy, .realName)
        XCTAssertEqual(detail.comments.count, detail.post.commentCount)
        XCTAssertEqual(detail.comments.first?.authorText, "이시우")
    }

    func testLikeToggleUpdatesBoard() async throws {
        let container = makeContainer()
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()

        await viewModel.toggleLike()
        XCTAssertEqual(viewModel.detail?.isLiked, true)
        XCTAssertEqual(viewModel.detail?.post.likeCount, 13)

        let board = container.makeBoardViewModel()
        await board.load()
        XCTAssertEqual(board.posts.first { $0.id == 41 }?.likeCount, 13)

        await viewModel.toggleLike()
        XCTAssertEqual(viewModel.detail?.isLiked, false)
        XCTAssertEqual(viewModel.detail?.post.likeCount, 12)
    }

    // MARK: 10-8 더보기 · 10-10 신고

    func testReportOthersPost() async {
        let viewModel = makeContainer().makePostDetailViewModel(postId: 41)
        await viewModel.load()

        await viewModel.report(.spam)
        XCTAssertEqual(viewModel.toastMessage, "신고를 접수했어요")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(PostReportReason.allCases.map(\.title), ["욕설 · 비하", "개인정보 노출", "광고 · 도배", "기타"])
    }

    func testDeleteOwnPostRemovesFromBoard() async {
        let container = makeContainer()
        let viewModel = container.makePostDetailViewModel(postId: 31)
        await viewModel.load()
        XCTAssertFalse(viewModel.canReport, "내 글은 신고 대신 삭제")
        XCTAssertTrue(viewModel.canDelete)

        await viewModel.delete()
        XCTAssertTrue(viewModel.isDeleted)

        let board = container.makeBoardViewModel()
        await board.load()
        XCTAssertFalse(board.posts.contains { $0.id == 31 })
    }

    func testCannotDeleteOthersPost() async throws {
        let container = makeContainer()
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let post = try XCTUnwrap(viewModel.detail?.post)

        do {
            try await container.deletePostUseCase.execute(post: post)
            XCTFail("남의 글은 지울 수 없어요")
        } catch AppError.forbidden {
            // 기대한 결과
        }
    }

    // MARK: 10-2 게시글 작성 · 10-9 게시 완료

    func testPublishAnonymousPost() async throws {
        let container = makeContainer()
        let viewModel = container.makePostComposeViewModel()
        XCTAssertFalse(viewModel.didRestoreDraft)
        XCTAssertFalse(viewModel.canPublish, "카테고리 · 제목 · 본문이 있어야 해요")
        XCTAssertEqual(viewModel.publishTitle, "익명으로 게시하기")

        viewModel.draft.category = .question
        viewModel.draft.title = "  점심 메뉴 추천해 주세요  "
        viewModel.draft.body = "회사 근처 맛집이 궁금해요."
        XCTAssertTrue(viewModel.canPublish)
        XCTAssertEqual(viewModel.bodyCountText, "15 / 5,000")

        await viewModel.publish()
        let post = try XCTUnwrap(viewModel.publishedPost)
        XCTAssertEqual(post.title, "점심 메뉴 추천해 주세요", "앞뒤 공백은 지워요")
        XCTAssertTrue(post.isAnonymous)
        XCTAssertTrue(post.isMine)
        XCTAssertEqual(viewModel.completionMessage, "익명으로 게시되어 작성자는 표시되지 않아요.")

        let board = container.makeBoardViewModel()
        await board.load()
        XCTAssertTrue(board.posts.contains { $0.id == post.id && $0.isMine })

        let detail = container.makePostDetailViewModel(postId: post.id)
        await detail.load()
        XCTAssertEqual(detail.detail?.body, "회사 근처 맛집이 궁금해요.")
        XCTAssertEqual(detail.detail?.commentPolicy, .anonymous)
        XCTAssertTrue(detail.canDelete)
    }

    func testDraftSaveRestoreAndClear() async {
        let container = makeContainer()
        let empty = container.makePostComposeViewModel()
        XCTAssertFalse(empty.saveDraft(), "빈 글은 저장하지 않아요")

        let first = container.makePostComposeViewModel()
        first.setAnonymous(false)
        first.draft.title = "임시 제목"
        XCTAssertTrue(first.saveDraft())

        let restored = container.makePostComposeViewModel()
        XCTAssertTrue(restored.didRestoreDraft)
        XCTAssertEqual(restored.draft.title, "임시 제목")
        XCTAssertFalse(restored.draft.isAnonymous)
        XCTAssertEqual(restored.publishTitle, "실명으로 게시하기")

        restored.draft.category = .free
        restored.draft.body = "본문"
        await restored.publish()
        XCTAssertEqual(restored.completionMessage, "실명으로 게시되어 이름과 소속이 함께 보여요.")
        XCTAssertFalse(container.makePostComposeViewModel().didRestoreDraft, "게시하면 임시 저장은 지워요")
    }

    func testImageAttachmentRules() {
        let viewModel = makeContainer().makePostComposeViewModel()
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0])

        viewModel.addImages([Data("not image".utf8)])
        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.errorMessage = nil
        viewModel.addImages([png, jpeg, png, jpeg, png, jpeg])
        XCTAssertEqual(viewModel.attachments.count, 5, "최대 5장")
        XCTAssertEqual(viewModel.imageCountText, "5 / 5")
        XCTAssertFalse(viewModel.canAddImage)
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.removeImage(viewModel.attachments[0])
        XCTAssertTrue(viewModel.canAddImage)
    }

    // MARK: 10-4 댓글 작성

    func testAnonymousCommentsShowWithoutNumbers() async throws {
        let container = makeContainer()
        let compose = container.makeCommentComposeViewModel(postId: 41, userName: "옥물결")
        await compose.load()
        XCTAssertTrue(compose.draft.isAnonymous, "원글 정책이 익명이면 익명이 기본")
        XCTAssertEqual(compose.realNameTitle, "실명 · 옥물결")
        XCTAssertTrue(compose.originText.hasPrefix("원글 · 익명 · "))
        XCTAssertFalse(compose.canSubmit)
        XCTAssertEqual(compose.submitTitle, "익명으로 댓글 등록")

        compose.draft.body = "저도 줄이는 중이에요"
        XCTAssertEqual(compose.previewName, "익명")
        await compose.submit()
        XCTAssertTrue(compose.didSubmit)

        let again = container.makeCommentComposeViewModel(postId: 41, userName: "옥물결")
        await again.load()
        again.draft.body = "화이팅!"
        await again.submit()

        let detail = container.makePostDetailViewModel(postId: 41)
        await detail.load()
        let authors = detail.detail?.comments.map(\.authorText) ?? []
        XCTAssertEqual(authors.sorted(), ["익명", "익명", "익명", "익명 · 글쓴이"], "서버는 익명 번호를 주지 않아요")
        XCTAssertEqual(detail.detail?.comments.filter(\.isMine).count, 2)
        XCTAssertEqual(detail.detail?.post.commentCount, 4)
    }

    func testRealNameCommentOnMyPost() async throws {
        let container = makeContainer()
        let compose = container.makeCommentComposeViewModel(postId: 31, userName: "옥물결")
        await compose.load()
        XCTAssertFalse(compose.draft.isAnonymous, "실명 글은 실명 댓글이 기본")
        XCTAssertTrue(compose.originText.hasPrefix("원글 · 옥물결 · 실명 · "))

        compose.draft.body = "책 목록 업데이트했어요"
        XCTAssertEqual(compose.previewName, "옥물결")
        await compose.submit()

        let detail = container.makePostDetailViewModel(postId: 31)
        await detail.load()
        XCTAssertEqual(detail.detail?.comments.last?.authorText, "옥물결 · 글쓴이")
    }

    func testBoardDateLabels() {
        XCTAssertEqual(TSFormat.dayLabel(Date(), now: Date()), "오늘")
        XCTAssertTrue(TSFormat.dayTime(Date(), now: Date()).hasPrefix("오늘 "))
    }
}
