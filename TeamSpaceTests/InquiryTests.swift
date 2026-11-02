import XCTest
@testable import TeamSpace

@MainActor
final class InquiryTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 11-1 내 문의

    func testMyInquiriesLatestFirstAndFilters() async {
        let viewModel = makeContainer().makeMyInquiriesViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.inquiries.map(\.id), [44, 43, 42, 41], "최신순")
        XCTAssertEqual(viewModel.count(of: .all), 4)
        let answered = viewModel.inquiries.first { $0.id == 42 }
        XCTAssertTrue(answered?.metaText.hasPrefix("NativeOps · ") == true)
        XCTAssertTrue(answered?.metaText.hasSuffix(" · 익명") == true)
        XCTAssertTrue(answered?.replyTitle?.hasPrefix("NativeOps 답변 · ") == true)

        viewModel.filter = .status(.answered)
        XCTAssertEqual(viewModel.inquiries.map(\.id), [42])
        viewModel.filter = .status(.rejected)
        XCTAssertEqual(viewModel.inquiries.map(\.id), [41])
        XCTAssertTrue(viewModel.inquiries.first?.replyTitle?.hasPrefix("NativeOps 반려 · ") == true)
        XCTAssertEqual(InquiryFilter.allCases.map(\.title), ["전체", "접수", "검토 중", "답변 완료", "반려"])
    }

    // MARK: 11-4 문의 상세 · 11-7 반려

    func testAnsweredDetail() async throws {
        let viewModel = makeContainer().makeInquiryDetailViewModel(inquiryId: 42)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)

        XCTAssertEqual(detail.history.map(\.status), [.received, .reviewing, .answered])
        XCTAssertTrue(detail.history.first?.detailText.hasSuffix("NativeOps에 전달") == true)
        XCTAssertTrue(detail.inquiry.reply?.body.hasPrefix("좋은 의견 감사합니다.") == true)
        XCTAssertEqual(detail.reference?.route, .ruleDetail(id: "meeting-principles"), "payload 에 reference 가 있으면 읽어요 (백엔드 협의안)")
        XCTAssertEqual(detail.history.last?.actor, "양지우", "답변한 사람은 answer.who")
        XCTAssertEqual(viewModel.followUpTitle, "이 답변에 후속 문의하기")
    }

    func testRejectedAndReviewingDetail() async {
        let container = makeContainer()
        let rejected = container.makeInquiryDetailViewModel(inquiryId: 41)
        await rejected.load()
        XCTAssertEqual(rejected.detail?.inquiry.status, .rejected)
        XCTAssertEqual(rejected.detail?.history.map(\.status), [.received, .reviewing, .rejected])
        XCTAssertEqual(rejected.followUpTitle, "다시 문의하기")

        let reviewing = container.makeInquiryDetailViewModel(inquiryId: 43)
        await reviewing.load()
        XCTAssertNil(reviewing.followUpTitle, "처리 중에는 후속 문의 버튼이 없어요")
    }

    func testServerInquiryDecoding() throws {
        let json = #"{"items":[{"id":"9","type":"문의","dept":"FA","title":"정산","body":"언제 되나요","anonymous":true,"author":"익명","status":"해결됨","steps":["2026-10-20T09:30:00.123456+09:00","2026-10-21T10:00:00+09:00","2026-10-22T11:00:00+09:00"],"answer":{"who":"김민준","whoId":"2","at":"2026-10-22T11:00:00+09:00","text":"이번 주에 돼요."},"replies":[]},{"id":"8","type":"건의","dept":"NativeOps","title":"공간","body":"주말","anonymous":false,"author":"옥물결","status":"접수","steps":["2026-10-19T09:00:00","",""],"answer":null,"replies":[]}],"nextCursor":"8"}"#
        let page = try JSONCoder.makeDecoder().decode(CursorPageDTO<ServerInquiryDTO>.self, from: Data(json.utf8))
        XCTAssertEqual(page.nextCursor, "8", "id 커서")

        let solved = page.items[0].toDetail()
        XCTAssertEqual(solved.inquiry.id, 9)
        XCTAssertEqual(solved.inquiry.department, .fa)
        XCTAssertEqual(solved.inquiry.status, .answered, "해결됨은 답변 완료로 봐요")
        XCTAssertEqual(solved.inquiry.reply?.body, "이번 주에 돼요.")
        XCTAssertEqual(solved.history.map(\.status), [.received, .reviewing, .answered])
        XCTAssertEqual(solved.history.first?.note, "FA에 전달")

        let received = page.items[1].toDetail()
        XCTAssertEqual(received.inquiry.department, .nativeOps)
        XCTAssertEqual(received.history.map(\.status), [.received], "빈 단계는 건너뛰어요")
        XCTAssertNil(received.inquiry.reply)
    }

    // MARK: 11-2 문의 작성 · 11-3 접수

    func testSubmitInquiry() async throws {
        let container = makeContainer()
        let compose = container.makeInquiryComposeViewModel(context: .blank)
        XCTAssertEqual(compose.draft.department, .nativeOps)
        XCTAssertEqual(compose.draft.department.scopeText, "NativeOps · 팀 운영 및 업무 환경")
        XCTAssertEqual(compose.submitTitle, "익명으로 문의 제출")
        XCTAssertFalse(compose.canSubmit)

        compose.draft.title = "활동 공간 이용 시간을 알고 싶어요"
        compose.draft.body = "주말에도 이용할 수 있나요?"
        await compose.submit()
        let submitted = try XCTUnwrap(compose.submitted)
        XCTAssertEqual(submitted.status, .received)
        XCTAssertEqual(compose.submittedMessage, "NativeOps가 검토 후 답변하면 알림으로 알려드려요.")

        let mine = container.makeMyInquiriesViewModel()
        await mine.load()
        XCTAssertEqual(mine.inquiries.first?.id, submitted.id)

        let detail = container.makeInquiryDetailViewModel(inquiryId: submitted.id)
        await detail.load()
        XCTAssertEqual(detail.detail?.history.map(\.note), ["NativeOps에 전달"])
    }

    func testComposeContexts() async throws {
        let container = makeContainer()
        let detail = container.makeInquiryDetailViewModel(inquiryId: 42)
        await detail.load()
        let inquiry = try XCTUnwrap(detail.detail?.inquiry)

        let followUp = container.makeInquiryComposeViewModel(context: .followUp(inquiry))
        XCTAssertTrue(followUp.isFollowUp)
        XCTAssertEqual(followUp.draft.title, "[후속] 회의실 예약 기준을 정해 주세요")
        XCTAssertEqual(followUp.draft.followUpOf, 42)

        let access = container.makeInquiryComposeViewModel(context: InquiryComposeContext(department: .fa, title: "권한"))
        access.draft.isAnonymous = false
        XCTAssertEqual(access.draft.department, .fa)
        XCTAssertEqual(access.submitTitle, "실명으로 문의 제출")
    }

    // MARK: 11-5 문의 받은함

    private let manager = AuthUser(id: 9, name: "양지우", roles: [.leader])

    func testInboxOnlyForManagers() async {
        let member = makeContainer().makeInquiryInboxViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.member]))
        await member.load()
        guard case .forbidden = member.state else { return XCTFail("일반 구성원은 받은함을 볼 수 없어요") }
    }

    func testInboxItemsCountsAndLogs() async throws {
        let viewModel = makeContainer().makeInquiryInboxViewModel(user: manager)
        await viewModel.load()

        XCTAssertEqual(viewModel.roleTitle, "NativeOps 담당자 권한")
        XCTAssertEqual(viewModel.items.map(\.id), [53, 52, 51, 42, 41], "NativeOps 문의만 · 최신 접수순")
        XCTAssertEqual(viewModel.count(of: .status(.received)), 2)
        XCTAssertEqual(viewModel.count(of: .status(.reviewing)), 1)
        XCTAssertTrue(viewModel.filters.contains(.status(.rejected)))

        let unassigned = try XCTUnwrap(viewModel.items.first { $0.id == 52 })
        XCTAssertEqual(unassigned.assigneeText, "담당 미배정 · 확인 및 담당 배정 필요")
        XCTAssertEqual(unassigned.actionTitle, "문의 확인 · 담당 배정")
        XCTAssertEqual(unassigned.authorText, "익명 · 신원 표시 안 함")
        XCTAssertEqual(viewModel.items.first?.authorText, "실명 · 이시우")
        XCTAssertTrue(viewModel.items.first { $0.id == 51 }?.assigneeText.hasSuffix("검토 시작") == true, "서버는 단계 메모가 없어 단계 이름으로 채워요")

        XCTAssertEqual(viewModel.recentLogs.first?.title, "신규 구성원 안내 자료를 제안해요")
        XCTAssertTrue(viewModel.recentLogs.first?.detailText.hasSuffix("양지우 · 접수 → 검토 중") == true)

        viewModel.query = "회의"
        XCTAssertEqual(viewModel.items.map(\.id), [53, 42, 41])
    }

    // MARK: 11-6 검토 · 공식 답변

    func testAssignThenAnswerWithRule() async throws {
        let viewModel = makeContainer().makeInquiryReviewViewModel(inquiryId: 52, user: manager)
        await viewModel.load()
        XCTAssertEqual(viewModel.assignees, ["양지우"], "서버가 담당자 목록을 주지 않아 나에게만 배정해요")
        XCTAssertFalse(viewModel.rules.isEmpty)

        await viewModel.assign("양지우")
        XCTAssertEqual(viewModel.item?.assignee, "양지우")
        XCTAssertEqual(viewModel.item?.inquiry.status, .reviewing, "배정하면 검토 중")
        XCTAssertEqual(viewModel.statusChangeText, "검토 중 → 답변 완료")

        viewModel.draft.body = "평일 9시부터 22시까지 이용할 수 있어요."
        viewModel.draft.referenceRuleId = "onboarding"
        XCTAssertEqual(viewModel.selectedRule?.title, "신규 멤버 온보딩 규칙")
        await viewModel.submit()

        XCTAssertEqual(viewModel.item?.inquiry.status, .answered)
        XCTAssertEqual(viewModel.item?.reference?.title, "신규 멤버 온보딩 규칙")
        XCTAssertEqual(viewModel.item?.history.last?.actor, "양지우")
        XCTAssertFalse(viewModel.isEditable)
        XCTAssertEqual(viewModel.toastMessage, "공식 답변을 등록했어요")
    }

    func testRejectReachesAuthorAndClosedInquiryIsLocked() async throws {
        let container = makeContainer()
        let compose = container.makeInquiryComposeViewModel(context: .blank)
        compose.draft.title = "회의실 앱 예약"
        compose.draft.body = "앱에서 예약하고 싶어요."
        await compose.submit()
        let mine = try XCTUnwrap(compose.submitted)

        let review = container.makeInquiryReviewViewModel(inquiryId: mine.id, user: manager)
        await review.load()
        review.draft.kind = .reject
        review.draft.body = "학교 시설이라 앱 예약은 어려워요."
        XCTAssertEqual(review.submitTitle, "반려 사유 등록")
        await review.submit()
        XCTAssertEqual(review.item?.inquiry.status, .rejected)

        let detail = container.makeInquiryDetailViewModel(inquiryId: mine.id)
        await detail.load()
        XCTAssertEqual(detail.detail?.inquiry.reply?.body, "학교 시설이라 앱 예약은 어려워요.", "작성자 상세에도 보여요")
        XCTAssertEqual(detail.followUpTitle, "다시 문의하기")

        let answered = container.makeInquiryReviewViewModel(inquiryId: 42, user: manager)
        await answered.load()
        XCTAssertFalse(answered.isEditable, "답변이 끝난 문의는 고칠 수 없어요")
    }

    func testAdminRequestsUseServerShape() throws {
        let reject = ServerInquiryPatchRequestDTO(status: InquiryStatus.rejected.serverValue, answer: "어려워요")
        let rejectJSON = try XCTUnwrap(String(data: JSONCoder.makeEncoder().encode(reject), encoding: .utf8))
        XCTAssertTrue(rejectJSON.contains(#""status":"반려""#))
        let answer = ServerInquiryAnswerRequestDTO(text: "답변", referenceRuleId: "8")
        let answerJSON = try XCTUnwrap(String(data: JSONCoder.makeEncoder().encode(answer), encoding: .utf8))
        XCTAssertTrue(answerJSON.contains(#""referenceRuleId":"8""#), "서버 answer 는 dict[str, str] 이라 문자열로 보내요")
    }

    // MARK: 연결

    func testInquiryAnswerNotificationRoutes() {
        XCTAssertEqual(NotificationType.inquiryAnswer.targetRoute(deepLink: "/inquiries/42"), .inquiryDetail(id: 42))
        XCTAssertEqual(NotificationType.inquiryAnswer.targetRoute(deepLink: nil), .myInquiries)
    }
}
