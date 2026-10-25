import XCTest
@testable import TeamSpace

@MainActor
final class ProjectTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 08-1 전체 프로젝트 탐색

    func testProjectListFilters() async {
        let viewModel = makeContainer().makeProjectListViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.projects.first?.name, "Book-on", "최근 업데이트순")
        XCTAssertEqual(viewModel.countText, "전체 프로젝트 5개")
        XCTAssertEqual(viewModel.projects.first?.cardDescription.hasSuffix("iOS 1명 모집"), true)

        viewModel.statusFilter = .completed
        XCTAssertEqual(viewModel.projects.map(\.name), ["Inspace 리서치"])
        XCTAssertEqual(viewModel.projects.first?.linkTitle, "결과와 문서 보기")

        viewModel.statusFilter = .all
        viewModel.recruitingOnly = true
        XCTAssertEqual(viewModel.projects.map(\.name), ["Book-on", "Native 팀 가이드"])

        viewModel.recruitingOnly = false
        viewModel.department = "NativeOps"
        viewModel.query = "가이드"
        XCTAssertEqual(viewModel.projects.map(\.name), ["Native 팀 가이드"])
    }

    func testInterestFilterUsesProfileInterests() async {
        let viewModel = makeContainer().makeProjectListViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.interests, ["UI", "타이포"])
        viewModel.interestOnly = true
        XCTAssertTrue(viewModel.projects.isEmpty, "UI · 타이포 직군 모집은 없어요")
    }

    // MARK: 08-2 프로젝트 상세

    func testProjectDetail() async {
        let joined = makeContainer().makeProjectDetailViewModel(projectId: 1)
        await joined.load()
        XCTAssertEqual(joined.detail?.members.count, 6)
        XCTAssertEqual(joined.detail?.members.first?.role, "PM")
        XCTAssertEqual(joined.detail?.project.openings.first?.title, "iOS 개발")
        XCTAssertFalse(joined.canApply, "이미 참여 중이면 신청 버튼 대신 일정 보기")

        let planned = makeContainer().makeProjectDetailViewModel(projectId: 4)
        await planned.load()
        XCTAssertTrue(planned.canApply)
        XCTAssertEqual(planned.detail?.project.status.badgeTitle, "예정")
    }

    // MARK: 08-8 일정과 변경 이력

    func testTimeline() async {
        let viewModel = makeContainer().makeProjectTimelineViewModel(projectId: 1)
        await viewModel.load()

        XCTAssertEqual(viewModel.title, "Book-on의 다음 단계")
        XCTAssertEqual(viewModel.badgeText, "진행 중 · 내 참여 프로젝트")
        XCTAssertEqual(viewModel.timeline?.milestones.map(\.title), ["핵심 기능 구현 완료", "위젯·QA 점검", "출시 준비", "출시"])
        XCTAssertEqual(viewModel.latestChange?.title, "QA 점검 일정이 변경됐어요", "최근 변경이 위로")
        XCTAssertEqual(viewModel.latestChange?.beforeText, "10.22 14:00–15:00")
        XCTAssertEqual(viewModel.olderChanges.first?.summaryText, "10.14 14:00 → 15:00 · 논의 자료 보완")

        guard let older = viewModel.olderChanges.first else { return XCTFail("지난 변경이 있어야 해요") }
        viewModel.toggle(older)
        XCTAssertTrue(viewModel.expandedChangeIds.contains(older.id))
    }

    // MARK: 08-3 ~ 08-6 모집 · 참여 신청

    func testRecruitmentAndApply() async {
        let container = makeContainer()
        let joined = container.makeRecruitmentViewModel(projectId: 1)
        await joined.load()
        XCTAssertEqual(joined.post?.roleBadgeText, "iOS · 1명")
        XCTAssertEqual(joined.post?.canApply, false, "이미 참여 중인 프로젝트")
        XCTAssertEqual(joined.post?.applyButtonTitle, "이미 참여 중인 프로젝트예요")

        let viewModel = container.makeRecruitmentViewModel(projectId: 4)
        await viewModel.load()
        XCTAssertEqual(viewModel.post?.canApply, true)

        viewModel.message = "   "
        XCTAssertFalse(viewModel.canSubmit, "한 마디가 비어 있으면 신청할 수 없어요")
        viewModel.availability = .twentyHours
        viewModel.message = "온보딩 문서를 다듬어 본 경험이 있어요."
        await viewModel.submit()

        XCTAssertTrue(viewModel.isSubmittedAlertPresented)
        XCTAssertEqual(viewModel.post?.myApplicationStatus, .submitted, "다시 불러오면 신청 완료")

        let mine = container.makeMyApplicationsViewModel()
        await mine.load()
        XCTAssertEqual(mine.applications.first?.projectName, "Native 팀 가이드", "방금 낸 신청이 맨 위")
        XCTAssertEqual(mine.count(of: .submitted), 2)
    }

    func testMyApplicationsCancel() async {
        let viewModel = makeContainer().makeMyApplicationsViewModel()
        await viewModel.load()

        XCTAssertEqual(ApplicationFilter.allCases.map { viewModel.count(of: $0) }, [4, 1, 1, 1, 1])
        guard let reviewing = viewModel.applications.first(where: { $0.status == .reviewing }) else {
            return XCTFail("검토 중인 신청이 있어야 해요")
        }
        XCTAssertTrue(viewModel.isExpanded(reviewing), "검토 중인 신청은 펼쳐서 보여줘요")
        XCTAssertEqual(reviewing.progressSteps.map(\.isDone), [true, true, false])

        viewModel.pendingCancel = reviewing
        await viewModel.confirmCancel()
        XCTAssertEqual(viewModel.count(of: .all), 3)

        guard let accepted = viewModel.applications.first(where: { $0.status == .accepted }) else {
            return XCTFail("참여 확정 신청이 있어야 해요")
        }
        viewModel.pendingCancel = accepted
        await viewModel.confirmCancel()
        XCTAssertEqual(viewModel.errorMessage, "결과가 확정된 신청은 취소할 수 없어요.")
    }

    // MARK: 08-7 PM 지원자 검토

    func testApplicantReview() async {
        let viewModel = makeContainer().makeApplicantReviewViewModel(projectId: 1)
        await viewModel.load()

        XCTAssertEqual(viewModel.board?.applicants.map(\.name), ["옥물결", "오잉", "잉오"], "검토 중 → 접수, 먼저 신청한 순")
        XCTAssertEqual(viewModel.selected?.name, "옥물결", "첫 검토 대상을 미리 골라둬요")
        XCTAssertEqual(viewModel.headcountText, "1명 · 확정 0명")
        XCTAssertEqual(viewModel.progressText, "접수 1 · 검토 중 2")
        XCTAssertFalse(viewModel.canSubmit, "사유를 적어야 등록할 수 있어요")

        viewModel.reason = "위젯 개발 경험과 일정이 잘 맞아요."
        await viewModel.submit()

        XCTAssertEqual(viewModel.headcountText, "1명 · 확정 1명")
        XCTAssertNotNil(viewModel.doneMessage)
        XCTAssertNil(viewModel.selectedId)
    }
}
