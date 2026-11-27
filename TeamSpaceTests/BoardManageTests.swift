import XCTest
@testable import TeamSpace

/// 10 게시판 — 조회순 정렬 · 댓글 고치기 · 지우기 · 상단 고정(Admin)
@MainActor
final class BoardManageTests: XCTestCase {
    private var client: APIClient!
    private var container: DIContainer!

    override func setUp() async throws {
        let tokenStorage = InMemoryTokenStorage()
        client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        container = DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    /// 41번 글에 내 댓글을 하나 달아 둬요.
    private func addMyComment(_ text: String = "처음 쓴 댓글") async throws -> PostComment {
        try await BoardRepositoryImpl(client: client).createComment(postId: 41, draft: CommentDraft(isAnonymous: false, body: text))
    }

    func testSortByViews() async {
        XCTAssertTrue(PostListQuery(sort: .views).queryItems(cursor: nil, limit: 20).contains(URLQueryItem(name: "sort", value: "views")))

        let viewModel = container.makeBoardViewModel()
        await viewModel.load()
        viewModel.selectPeriod(.all)
        viewModel.selectSort(.views)
        await viewModel.waitForReload()
        let views = viewModel.posts.map(\.viewCount)
        XCTAssertFalse(views.isEmpty)
        XCTAssertEqual(views, views.sorted(by: >), "조회 많은 순")
        XCTAssertEqual(BoardSort.allCases.map(\.title), ["최신순", "인기순", "조회순"])
    }

    func testEditMyComment() async throws {
        let mine = try await addMyComment()
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let comment = try XCTUnwrap(viewModel.detail?.comments.first { $0.id == mine.id })
        let others = try XCTUnwrap(viewModel.detail?.comments.first { !$0.isMine })
        XCTAssertTrue(viewModel.canEditComment(comment))
        XCTAssertFalse(viewModel.canEditComment(others), "남의 댓글은 못 고쳐요")
        XCTAssertFalse(viewModel.canDeleteComment(others), "Admin 이 아니면 남의 댓글은 못 지워요")

        viewModel.startEditing(comment)
        XCTAssertFalse(viewModel.canSaveComment, "안 바뀌었으면 저장 못 해요")
        viewModel.editingCommentText = "   "
        XCTAssertFalse(viewModel.canSaveComment)
        viewModel.editingCommentText = " 고친 댓글 "
        await viewModel.saveComment()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.editingComment, "저장하면 시트를 닫아요")
        XCTAssertEqual(viewModel.detail?.comments.first { $0.id == mine.id }?.body, "고친 댓글")
        XCTAssertEqual(viewModel.toastMessage, "댓글을 고쳤어요")

        let reloaded = container.makePostDetailViewModel(postId: 41)
        await reloaded.load()
        XCTAssertEqual(reloaded.detail?.comments.first { $0.id == mine.id }?.body, "고친 댓글", "서버에도 저장돼요")
    }

    func testDeleteMyComment() async throws {
        let mine = try await addMyComment()
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let before = try XCTUnwrap(viewModel.detail?.comments.count)
        viewModel.deletingComment = viewModel.detail?.comments.first { $0.id == mine.id }
        await viewModel.deleteComment()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.detail?.comments.count, before - 1)
        XCTAssertFalse(viewModel.detail?.comments.contains { $0.id == mine.id } ?? true)
        XCTAssertEqual(viewModel.toastMessage, "댓글을 지웠어요")
    }

    func testAdminDeletesOthersComment() async throws {
        let viewModel = container.makePostDetailViewModel(postId: 41, canModerate: true)
        await viewModel.load()
        let others = try XCTUnwrap(viewModel.detail?.comments.first { !$0.isMine })
        XCTAssertTrue(viewModel.canDeleteComment(others))
        XCTAssertFalse(viewModel.canEditComment(others), "Admin 도 남의 댓글 내용은 못 고쳐요")

        viewModel.deletingComment = others
        await viewModel.deleteComment()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.detail?.comments.contains { $0.id == others.id } ?? true)
    }

    func testCommentUseCaseBlocksOthers() async throws {
        let viewModel = container.makePostDetailViewModel(postId: 41)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)
        let others = try XCTUnwrap(detail.comments.first { !$0.isMine })
        let useCase = ManagePostCommentUseCase(boardRepository: BoardRepositoryImpl(client: client))
        do {
            _ = try await useCase.delete(detail, commentId: others.id, isAdmin: false)
            XCTFail("남의 댓글은 지울 수 없어요")
        } catch AppError.forbidden {}
        do {
            _ = try await useCase.update(detail, commentId: others.id, text: "바꿈")
            XCTFail("남의 댓글은 고칠 수 없어요")
        } catch AppError.forbidden {}
    }

    func testAdminPinsPost() async throws {
        let viewModel = container.makePostDetailViewModel(postId: 35, canModerate: true)
        await viewModel.load()
        XCTAssertTrue(viewModel.canPin)
        XCTAssertEqual(viewModel.pinTitle, "상단에 고정")

        await viewModel.togglePin()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.detail?.post.isPinned, true)
        XCTAssertEqual(viewModel.pinTitle, "고정 해제")
        XCTAssertEqual(viewModel.toastMessage, "게시글을 상단에 고정했어요")

        let board = container.makeBoardViewModel()
        await board.load()
        board.selectPeriod(.all)
        await board.waitForReload()
        XCTAssertEqual(board.posts.first?.id, 35, "고정한 글은 목록 맨 위")
        XCTAssertEqual(board.posts.first?.isPinned, true)

        await viewModel.togglePin()
        XCTAssertEqual(viewModel.detail?.post.isPinned, false)
        XCTAssertEqual(viewModel.toastMessage, "고정을 풀었어요")
    }

    func testMemberCannotPin() async throws {
        let viewModel = container.makePostDetailViewModel(postId: 35)
        await viewModel.load()
        XCTAssertFalse(viewModel.canPin)
        let detail = try XCTUnwrap(viewModel.detail)
        do {
            _ = try await PinPostUseCase(boardRepository: BoardRepositoryImpl(client: client)).execute(detail, isPinned: true, isAdmin: false)
            XCTFail("Admin 만 고정할 수 있어요")
        } catch AppError.forbidden {}
        XCTAssertTrue(AuthUser(id: 1, name: "a", roles: [.admin]).can(.moderatePosts))
        XCTAssertFalse(AuthUser(id: 2, name: "b", roles: [.leader]).can(.moderatePosts))
    }

    func testPinnedDecoding() throws {
        let json = #"{"id":"3","title":"t","body":"b","anonymous":false,"pinned":true,"createdAt":"2026-11-16T10:00:00+09:00"}"#
        XCTAssertTrue(try JSONCoder.makeDecoder().decode(ServerPostItemDTO.self, from: Data(json.utf8)).toEntity().isPinned)
    }
}
