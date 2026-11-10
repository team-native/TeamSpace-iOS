import XCTest
@testable import TeamSpace

@MainActor
final class ProposalTests: XCTestCase {
    private func makeContainer(defaultsName: String = #function) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        let defaults = UserDefaults(suiteName: "test.proposal.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsProposalDraftRepository.key)
        return DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            proposalDraftRepository: UserDefaultsProposalDraftRepository(defaults: defaults)
        )
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
        XCTAssertEqual(viewModel.statuses, [.received, .reviewing, .inProgress, .answered], "서버 상태에는 완료가 없고 답변 완료로 끝나요")

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

        XCTAssertFalse(detail.metaText.contains("조회"), "서버는 조회 수를 주지 않아요")
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
        XCTAssertTrue(last.headerText.hasPrefix("익명 · 제안자 · "), "익명 제안에 제안자가 단 댓글은 서버가 글쓴이로 가려요")
        XCTAssertEqual(viewModel.commentText, "")

        let list = container.makeProposalListViewModel()
        await list.load()
        XCTAssertEqual(list.proposals.first { $0.id == 12 }?.commentCount, 3)
    }

    func testServerProposalDecoding() throws {
        let json = #"{"id":"21","category":"PMO","title":"회의록","body":"양식을 통일해요","status":"반려","anonymous":false,"likes":3,"recommendCount":3,"commentCount":1,"createdAt":"2026-10-20T09:30:00.123456","mine":false,"author":"이시우","dept":"Design","answer":{"who":"안율","at":"2026-10-22T10:00:00+09:00","text":"이번엔 어려워요."},"history":[{"status":"접수","who":"이시우","at":"2026-10-20T09:30:00+00:00"},{"status":"반려","who":"안율","at":"2026-10-22T10:00:00+09:00"}],"comments":[{"id":"5","text":"저도요","createdAt":"2026-10-21T08:00:00","anonymous":false,"mine":true,"author":"이시우"},{"id":"6","text":"익명 의견","createdAt":"2026-10-21T09:00:00","anonymous":true,"mine":false}]}"#
        let detail = try JSONCoder.makeDecoder().decode(ServerProposalDTO.self, from: Data(json.utf8)).toDetail()

        XCTAssertEqual(detail.proposal.id, 21)
        XCTAssertEqual(detail.proposal.department, "PMO", "대상 부서는 category (dept 는 작성자 소속)")
        XCTAssertEqual(detail.proposal.status, .rejected)
        XCTAssertEqual(detail.proposal.status.title, "반려")
        XCTAssertTrue(ProposalPhase.done.contains(.rejected))
        XCTAssertEqual(detail.stepDates.map { $0.date != nil }, [true, false, false, true], "반려는 마지막 단계")
        XCTAssertEqual(detail.answer?.department, "PMO")
        XCTAssertEqual(detail.answer?.body, "이번엔 어려워요.")
        XCTAssertTrue(detail.comments[0].isProposer, "실명 제안자 이름과 같은 실명 댓글")
        XCTAssertTrue(detail.comments[0].isMine)
        XCTAssertTrue(detail.comments[1].isAnonymous)
        XCTAssertNil(detail.comments[1].authorName)
        XCTAssertEqual(ProposalStatus(serverValue: "협업 중"), .inProgress)
        XCTAssertNil(detail.viewCount, "서버가 views 를 안 주면 숨겨요")
        XCTAssertFalse(detail.isRecommended)
    }

    func testServerProposalDetailDecodesViewsAndRecommended() throws {
        let json = #"{"id":"22","category":"PMO","title":"t","body":"b","status":"접수","anonymous":true,"recommendCount":4,"commentCount":0,"createdAt":"2026-10-20T09:30:00","mine":false,"history":[],"views":17,"recommended":true,"comments":[]}"#
        let detail = try JSONCoder.makeDecoder().decode(ServerProposalDTO.self, from: Data(json.utf8)).toDetail()
        XCTAssertEqual(detail.viewCount, 17)
        XCTAssertTrue(detail.isRecommended)
    }

    func testProposalCommentAnonymousNumber() throws {
        let json = Data(#"{"id":"5","text":"t","anonymous":true,"author":"익명 2","anonymousNumber":2}"#.utf8)
        let comment = try JSONCoder.makeDecoder().decode(ServerProposalCommentDTO.self, from: json).toEntity(proposalAuthor: nil)
        XCTAssertEqual(comment.anonymousNumber, 2)
        XCTAssertTrue(comment.headerText.hasPrefix("익명 2 · "))
    }

    func testListLoadsEveryPage() async throws {
        let store = MockProposalStore()
        let first = try JSONCoder.makeDecoder().decode(
            CursorPageDTO<ServerProposalDTO>.self, from: Data(store.listJSON(limit: 3).utf8)
        )
        XCTAssertEqual(first.items.count, 3)
        XCTAssertEqual(first.nextCursor, "o:3")
        let last = try JSONCoder.makeDecoder().decode(
            CursorPageDTO<ServerProposalDTO>.self, from: Data(store.listJSON(cursor: "o:6", limit: 3).utf8)
        )
        XCTAssertEqual(last.items.count, 1)
        XCTAssertNil(last.nextCursor)
    }

    // MARK: 12-3 운영 제안 쓰기

    func testCreateAnonymousProposal() async throws {
        let container = makeContainer()
        let compose = container.makeProposalComposeViewModel()
        XCTAssertEqual(compose.draft.department, "NativeOps")
        XCTAssertEqual(compose.submitTitle, "익명으로 제안 올리기")
        XCTAssertFalse(compose.canSubmit)

        compose.draft.department = "Design"
        compose.draft.title = "디자인 리뷰 일정을 고정해요"
        compose.draft.body = "격주 목요일로 고정하면 준비하기 좋아요."
        await compose.submit()
        let proposal = try XCTUnwrap(compose.published)
        XCTAssertEqual(proposal.status, .received)
        XCTAssertTrue(proposal.isMine)
        XCTAssertEqual(compose.completionMessage, "익명으로 올라가 작성자는 표시되지 않아요. Design가 검토하면 진행 상태가 바뀌어요.")

        let list = container.makeProposalListViewModel()
        await list.load()
        XCTAssertEqual(list.proposals.first?.id, proposal.id, "새 제안이 맨 위")
        XCTAssertTrue(list.departments.contains("Design"))

        let detail = container.makeProposalDetailViewModel(proposalId: proposal.id)
        await detail.load()
        XCTAssertEqual(detail.detail?.stepDates.map { $0.date != nil }, [true, false, false, false])
    }

    func testProposalDraftSaveAndRestore() async {
        let container = makeContainer()
        XCTAssertFalse(container.makeProposalComposeViewModel().saveDraft(), "빈 글은 저장하지 않아요")

        let first = container.makeProposalComposeViewModel()
        first.draft.title = "임시 제안"
        first.draft.isAnonymous = false
        XCTAssertTrue(first.saveDraft())

        let restored = container.makeProposalComposeViewModel()
        XCTAssertTrue(restored.didRestoreDraft)
        XCTAssertEqual(restored.draft.title, "임시 제안")
        XCTAssertEqual(restored.submitTitle, "실명으로 제안 올리기")

        restored.draft.body = "내용"
        await restored.submit()
        XCTAssertNotNil(restored.published)
        XCTAssertFalse(container.makeProposalComposeViewModel().didRestoreDraft, "올리면 임시 저장은 지워요")
    }

    // MARK: 12-2c 담당자 처리 (PATCH /admin/proposals/{id})

    private let admin = AuthUser(id: 9, name: "양지우", roles: [.admin])
    private let member = AuthUser(id: 1, name: "옥물결", roles: [.member])

    func testManageCardOnlyForAdminOrSameDepartment() async throws {
        let container = makeContainer()
        let other = container.makeProposalDetailViewModel(proposalId: 16, user: member)
        await other.load()
        XCTAssertFalse(other.canManage, "내 부서(Design)와 담당 부서(NativeOps)가 달라요")
        XCTAssertFalse(container.makeProposalDetailViewModel(proposalId: 16).canManage, "로그인 정보가 없으면 숨겨요")

        let compose = container.makeProposalComposeViewModel()
        compose.draft.department = "Design"
        compose.draft.title = "디자인 리뷰 일정을 고정해요"
        compose.draft.body = "격주 목요일로 고정하면 준비하기 좋아요."
        await compose.submit()
        let created = try XCTUnwrap(compose.published)
        let same = container.makeProposalDetailViewModel(proposalId: created.id, user: member)
        await same.load()
        XCTAssertTrue(same.canManage, "내 부서가 담당 부서면 보여요")
        XCTAssertEqual(same.manageDraft.action, .reviewing, "접수 상태면 검토 중부터 골라 둬요")

        let byAdmin = container.makeProposalDetailViewModel(proposalId: 16, user: admin)
        await byAdmin.load()
        XCTAssertTrue(byAdmin.canManage, "Admin 은 모든 제안을 처리해요")
    }

    func testAdminChangesStatus() async throws {
        let viewModel = makeContainer().makeProposalDetailViewModel(proposalId: 16, user: admin)
        await viewModel.load()
        XCTAssertEqual(viewModel.manageDraft.action, .inProgress, "검토 중이면 진행 중을 골라 둬요")

        viewModel.manageDraft.action = .reviewing
        XCTAssertFalse(viewModel.canSubmitManage, "이미 검토 중이에요")
        viewModel.manageDraft.action = .inProgress
        XCTAssertTrue(viewModel.canSubmitManage)
        await viewModel.submitManage()

        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertEqual(detail.proposal.status, .inProgress)
        XCTAssertEqual(detail.steps.map(\.status), [.received, .reviewing, .inProgress], "서버처럼 이력이 남아요")
        XCTAssertEqual(viewModel.toastMessage, "진행 중으로 바꿨어요")
        XCTAssertEqual(viewModel.manageDraft.action, .answer, "다음은 답변이에요")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAdminAnswersProposal() async throws {
        let viewModel = makeContainer().makeProposalDetailViewModel(proposalId: 12, user: admin)
        await viewModel.load()
        viewModel.manageDraft.action = .answer
        viewModel.manageDraft.body = "   "
        XCTAssertFalse(viewModel.canSubmitManage, "답변이 비어 있으면 못 보내요")

        viewModel.manageDraft.body = "  다음 주부터 회의실 예약을 캘린더로 보여줄게요.  "
        await viewModel.submitManage()
        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertEqual(detail.proposal.status, .answered)
        XCTAssertEqual(detail.answer?.body, "다음 주부터 회의실 예약을 캘린더로 보여줄게요.")
        XCTAssertEqual(viewModel.toastMessage, "공식 답변을 등록했어요")
        XCTAssertEqual(viewModel.manageDraft.body, "", "보내면 비워요")
    }

    func testAdminRejectsWithReason() async throws {
        let viewModel = makeContainer().makeProposalDetailViewModel(proposalId: 13, user: admin)
        await viewModel.load()
        viewModel.manageDraft.action = .reject
        viewModel.manageDraft.body = "이미 정기 회고 일정이 있어요."
        await viewModel.submitManage()

        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertEqual(detail.proposal.status, .rejected, "반려 사유를 남겨도 반려 상태로 남아요")
        XCTAssertEqual(detail.answer?.body, "이미 정기 회고 일정이 있어요.")
        XCTAssertEqual(viewModel.toastMessage, "반려했어요")
    }

    func testManageRequestOmitsAnswerWhenStatusOnly() throws {
        let statusOnly = try JSONEncoder().encode(ServerProposalManageRequestDTO(status: "협업 중", answer: nil))
        XCTAssertEqual(String(decoding: statusOnly, as: UTF8.self), #"{"status":"협업 중"}"#)
        XCTAssertEqual(ProposalStatus.inProgress.serverValue, "협업 중")
    }
}
