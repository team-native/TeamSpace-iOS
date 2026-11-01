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
        XCTAssertEqual(detail.reference?.route, .ruleDetail(id: 5))
        XCTAssertEqual(viewModel.followUpTitle, "이 답변에 후속 문의하기")
    }

    func testRejectedAndReviewingDetail() async {
        let container = makeContainer()
        let rejected = container.makeInquiryDetailViewModel(inquiryId: 41)
        await rejected.load()
        XCTAssertEqual(rejected.detail?.inquiry.status, .rejected)
        XCTAssertEqual(rejected.detail?.reference?.route, .notices)
        XCTAssertEqual(rejected.detail?.reference?.linkTitle, "공지 보기")
        XCTAssertEqual(rejected.followUpTitle, "다시 문의하기")

        let reviewing = container.makeInquiryDetailViewModel(inquiryId: 43)
        await reviewing.load()
        XCTAssertNil(reviewing.followUpTitle, "처리 중에는 후속 문의 버튼이 없어요")
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

    // MARK: 연결

    func testInquiryAnswerNotificationRoutes() {
        XCTAssertEqual(NotificationType.inquiryAnswer.targetRoute(deepLink: "/inquiries/42"), .inquiryDetail(id: 42))
        XCTAssertEqual(NotificationType.inquiryAnswer.targetRoute(deepLink: nil), .myInquiries)
    }
}
