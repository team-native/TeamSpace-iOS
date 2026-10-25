import XCTest
@testable import TeamSpace

@MainActor
final class WorkspaceTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: 07-1 내 공간 대시보드

    func testHomeLoadsFigmaSummary() async throws {
        let user = AuthUser(id: 1, name: "옥물결", roles: [.member])
        let viewModel = makeContainer().makeWorkspaceHomeViewModel(user: user)

        await viewModel.load()

        let home = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(home.affiliation, "NativeLab / Design")
        XCTAssertEqual(home.todo.todayCount, 2)
        XCTAssertEqual(home.receivedApproval?.documentId, 11, "누르면 05 결재 상세가 열리는 문서")
        XCTAssertEqual(home.projects.map(\.progress), [68, 80])
        XCTAssertEqual(viewModel.upcomingSchedules.map(\.title), ["Book-on QA 점검", "Native 전체 회의"], "가까운 일정이 위로")
        XCTAssertEqual(viewModel.greeting, "옥물결 님, 오늘도 차근차근")
        XCTAssertEqual(user.workspaceRoleSummary, "일반 사용자 · 추가 운영 권한 없음")
    }

    func testDisplayTexts() {
        let submitted = WorkspaceSubmittedDocument(
            documentId: 1, title: "Book-on 테스트 기기 구매", amount: 420_000,
            submittedAt: date(2026, 10, 14), status: .reviewing, currentApproverName: "이시우"
        )
        XCTAssertEqual(submitted.metaText, "420,000원 · 10.14 제출 · 이시우 검토 중")

        let schedule = WorkspaceSchedule(
            id: 1, scope: .personal, title: "Book-on QA 점검",
            startsAt: date(2026, 10, 23, 15), endsAt: date(2026, 10, 23, 16), place: "온라인", note: "변경자 이시우"
        )
        XCTAssertEqual(schedule.badgeText, "10.23 · 개인 업무")
        XCTAssertEqual(schedule.metaText, "15:00–16:00 · 온라인 · 변경자 이시우")

        let records = WorkspaceRecords(
            latestPost: nil,
            proposalCount: 3,
            latestProposal: WorkspaceProposalPreview(title: "회의실 예약 현황을 한눈에 보고 싶어요", status: .reviewing, recommendCount: 32),
            inquiries: [
                WorkspaceInquiryPreview(title: "회의실 예약 기준", status: .answered),
                WorkspaceInquiryPreview(title: "안내 자료", status: .reviewing)
            ]
        )
        XCTAssertEqual(records.proposalText, "회의실 예약 현황을 한눈에… · 검토 중 · 추천 32")
        XCTAssertEqual(records.inquiryText, "회의실 예약 기준 · 답변 완료 / 안내 자료 · 검토 중")
        XCTAssertEqual(records.postText, "아직 남긴 글이 없어요.")
    }

    func testRoleSummaryByRole() {
        XCTAssertEqual(AuthUser(id: 1, name: "a", roles: [.member, .pm]).workspaceRoleSummary, "PM · 프로젝트 관리 · 결재 권한")
        XCTAssertEqual(AuthUser(id: 1, name: "a", roles: [.fa]).workspaceRoleSummary, "FA · 재무 상세 열람 권한")
    }

    // MARK: 07-2 나의 To-do

    func testTodoSectionsMatchFigma() async {
        let viewModel = makeContainer().makeTodoListViewModel(userName: "옥물결")

        await viewModel.load()

        XCTAssertEqual(viewModel.sections.map(\.kind), [.today, .upcoming, .done])
        XCTAssertEqual(viewModel.sections.first?.items.map(\.title), ["인원 지원 요청 검토", "QA 체크리스트 정리"])
        XCTAssertEqual(TodoSection.Kind.allCases.map { viewModel.count(of: $0) }, [2, 1, 1])
        XCTAssertEqual(viewModel.sections.first?.items.first?.badgeTitle(), "미완료 · 결재 대기")
        XCTAssertEqual(viewModel.sections.first?.items.first?.linkRoute, .approvalDetail(documentId: 11))
    }

    func testToggleMovesTodoToDoneAndBack() async {
        let viewModel = makeContainer().makeTodoListViewModel(userName: "옥물결")
        await viewModel.load()
        guard let todo = viewModel.sections.first?.items.first else { return XCTFail("오늘 할 일이 있어야 해요") }

        await viewModel.toggle(todo)
        XCTAssertEqual(viewModel.count(of: .today), 1)
        XCTAssertEqual(viewModel.count(of: .done), 2)

        guard let done = viewModel.sections.last?.items.first(where: { $0.id == todo.id }) else {
            return XCTFail("완료 섹션으로 옮겨져야 해요")
        }
        await viewModel.toggle(done)
        XCTAssertEqual(viewModel.count(of: .today), 2)
    }

    func testQuickAddValidationAndAdd() async {
        let viewModel = makeContainer().makeTodoListViewModel(userName: "옥물결")
        await viewModel.load()

        viewModel.newTitle = "   "
        XCTAssertFalse(viewModel.canAdd)
        XCTAssertEqual(AddTodoUseCase.validationMessage(title: String(repeating: "가", count: 41)), "제목은 40자까지 쓸 수 있어요.")

        viewModel.newTitle = "  회의록 정리  "
        viewModel.newProjectName = "Book-on"
        await viewModel.add()

        XCTAssertEqual(viewModel.count(of: .today), 3)
        XCTAssertTrue(viewModel.sections.first?.items.contains { $0.title == "회의록 정리" } ?? false, "앞뒤 공백은 빼고 저장")
        XCTAssertEqual(viewModel.newTitle, "", "추가하면 입력을 비워요")
        XCTAssertNil(viewModel.newProjectName)
    }

    func testTodoMetaText() {
        let now = date(2026, 10, 16, 12)
        let checklist = TodoItem(
            id: 1, title: "QA", dueAt: date(2026, 10, 16, 18), hasTime: true, endsAt: nil, place: nil,
            projectName: "Book-on", linkKind: .checklist, linkedId: 1, status: .open, completedAt: nil
        )
        XCTAssertEqual(checklist.metaText(now: now), "오늘 18:00 · Book-on · 프로젝트 업무")

        let schedule = TodoItem(
            id: 2, title: "QA 점검", dueAt: date(2026, 10, 23, 15), hasTime: true, endsAt: date(2026, 10, 23, 16),
            place: "온라인", projectName: "Book-on", linkKind: .schedule, linkedId: 1, status: .open, completedAt: nil
        )
        XCTAssertEqual(schedule.metaText(now: now), "10.23 15:00–16:00 · 온라인 · Book-on")
        XCTAssertEqual(schedule.badgeTitle(now: now), "예정")
    }

    // MARK: 07-3 내 공간 · 07-6 참여 프로젝트

    func testMenuShowsWaitingApprovalsAndAffiliation() async {
        let viewModel = makeContainer().makeWorkspaceMenuViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.member]))

        await viewModel.load()

        XCTAssertEqual(viewModel.affiliation, "NativeLab / Design")
        XCTAssertEqual(viewModel.waitingApprovals.count, 2, "검토 대기 · 검토 중인 받은 결재만")
        XCTAssertEqual(viewModel.latestWaiting?.title, "Book-on 프로젝트 인력 지원", "가장 최근 요청이 위로")
    }

    func testJoinedProjects() async {
        let viewModel = makeContainer().makeWorkspaceProjectsViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.projects.map(\.name), ["Book-on", "Native 팀스페이스"])
        XCTAssertEqual(viewModel.projects.first?.initial, "B")
        XCTAssertEqual(viewModel.projects.first?.periodText, "독서 기록 앱 · 07.01 – 11.30")
        XCTAssertEqual(ProjectRunStatus.inProgress.badgeTitle, "진행 중")
    }
}
