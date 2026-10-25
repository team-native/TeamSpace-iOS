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

    // MARK: 07-4 내가 제출한 문서 · 07-5 임시 저장

    func testMyDocumentsFilterAndSearch() async {
        let viewModel = makeContainer().makeMyDocumentsViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.documents.count, 7, "내가 올린 결재와 같은 문서")
        XCTAssertEqual(viewModel.kindFilters, [nil, .expense])

        viewModel.statusFilter = .draft
        XCTAssertEqual(viewModel.documents.map(\.title), ["11월 워크숍 장소 대관"])
        XCTAssertEqual(viewModel.documents.first?.linkRoute, .workspaceDrafts)

        viewModel.statusFilter = nil
        viewModel.query = "book-on"
        XCTAssertEqual(viewModel.documents.map(\.title), ["Book-on 테스트 기기 구매"], "대소문자 구분 없이 제목 · 프로젝트 검색")
    }

    func testMyDocumentProgressText() {
        let reviewing = MyDocument(
            id: 1, kind: .expense, title: "Book-on 테스트 기기 구매", amount: 420_000, status: .reviewing,
            projectName: "Book-on", summary: nil, submittedAt: date(2026, 10, 14), updatedAt: date(2026, 10, 14),
            currentApprover: DocumentPerson(name: "이시우", department: "PMO"), currentStepTitle: nil,
            decidedBy: nil, decidedAt: nil, rejectReason: nil
        )
        XCTAssertEqual(reviewing.headerText, "예산 품의서 · 제출 2026.10.14")
        XCTAssertEqual(reviewing.progressText, "420,000원 · 현재 결재자 이시우 · PMO")
        XCTAssertEqual(reviewing.linkTitle, "진행 상황 확인")

        let rejected = MyDocument(
            id: 3, kind: .expense, title: "디자인 툴 구독 예산", amount: nil, status: .rejected,
            projectName: nil, summary: nil, submittedAt: date(2026, 10, 10), updatedAt: date(2026, 10, 12),
            currentApprover: nil, currentStepTitle: nil, decidedBy: DocumentPerson(name: "김민준", department: "FA"),
            decidedAt: date(2026, 10, 12), rejectReason: "산출 근거를 보완해 주세요."
        )
        XCTAssertEqual(rejected.progressText, "김민준 · FA · 10.12 반려 사유: 산출 근거를 보완해 주세요.")
        XCTAssertEqual(rejected.linkRoute, .approvalDetail(documentId: 3))
    }

    func testDraftDeleteRemovesOnlyDrafts() async {
        let container = makeContainer()
        let viewModel = container.makeDraftDocumentsViewModel()
        await viewModel.load()
        XCTAssertEqual(viewModel.drafts.map(\.title), ["11월 워크숍 장소 대관"])
        XCTAssertEqual(viewModel.drafts.first?.kind.composeKind, .expense)

        viewModel.pendingDelete = viewModel.drafts.first
        await viewModel.confirmDelete()

        guard case .empty = viewModel.state else { return XCTFail("지우고 나면 빈 화면") }
        XCTAssertNil(viewModel.pendingDelete)

        let submitted = MyDocument(
            id: 1, kind: .expense, title: "t", amount: nil, status: .pending, projectName: nil, summary: nil,
            submittedAt: Date(), updatedAt: Date(), currentApprover: nil, currentStepTitle: nil,
            decidedBy: nil, decidedAt: nil, rejectReason: nil
        )
        do {
            try await container.deleteDraftUseCase.execute(submitted)
            XCTFail("제출한 문서는 지울 수 없어요")
        } catch {
            XCTAssertEqual(error as? AppError, .invalidInput("제출한 문서는 삭제할 수 없어요. 결재 상세에서 요청을 취소해 주세요."))
        }
    }

    // MARK: 07-7 ~ 07-9 일정

    func testCalendarShowsTodayEvents() async {
        let viewModel = makeContainer().makeScheduleCalendarViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.selectedEvents.map(\.title), ["Book-on 디자인 리뷰", "iOS 스터디"])
        XCTAssertEqual(viewModel.selectedEvents.first?.listMetaText, "15:00 – 16:00 · 온라인")
        XCTAssertFalse(viewModel.selectedEvents.first?.opensFullDetail ?? true, "개인 일정은 07-9 시트")
        XCTAssertTrue(viewModel.selectedEvents.last?.opensFullDetail ?? false, "Native 일정은 07-8 상세")
        let monthDays = viewModel.days.compactMap(\.date)
        XCTAssertEqual(monthDays.count, Calendar.current.range(of: .day, in: .month, for: Date())?.count)
        XCTAssertEqual(viewModel.days.count - monthDays.count, Calendar.current.component(.weekday, from: monthDays[0]) - 1, "일요일부터 시작")
    }

    func testRespondFromSheet() async {
        // 오늘 0시 기준으로 보면 오늘 일정은 아직 끝나지 않았어요. (테스트 실행 시각과 무관하게)
        let container = makeContainer()
        let viewModel = ScheduleCalendarViewModel(
            fetchSchedulesUseCase: container.fetchSchedulesUseCase,
            respondScheduleUseCase: container.respondScheduleUseCase,
            now: { Calendar.current.startOfDay(for: Date()) }
        )
        await viewModel.load()
        viewModel.sheetEvent = viewModel.selectedEvents.first

        await viewModel.respond(.attend)

        XCTAssertNil(viewModel.sheetEvent, "응답하면 시트를 닫아요")
        XCTAssertEqual(viewModel.selectedEvents.first?.myResponse, .attend)
    }

    func testCannotRespondToEndedSchedule() async {
        let ended = ScheduleEvent(
            id: 5, scope: .personal, title: "지난 일정", startsAt: date(2026, 10, 1, 10), endsAt: date(2026, 10, 1, 11),
            place: "온라인", placeDetail: nil, organizerName: "a", participantCount: 1, isChanged: false
        )
        do {
            _ = try await makeContainer().respondScheduleUseCase.execute(ended, response: .attend, now: date(2026, 10, 2))
            XCTFail("끝난 일정에는 응답할 수 없어요")
        } catch {
            XCTAssertEqual(error as? AppError, .invalidInput("이미 끝난 일정이에요."))
        }
    }

    func testScheduleDetailAndReminders() async {
        let viewModel = makeContainer().makeScheduleDetailViewModel(scheduleId: 2)

        await viewModel.load()

        XCTAssertEqual(viewModel.detail?.event.title, "Native 전체 회의")
        XCTAssertEqual(viewModel.detail?.agenda.count, 4)
        XCTAssertEqual(viewModel.detail?.history.first?.title, "장소 변경", "최근 변경이 위로")
        XCTAssertNotNil(viewModel.savedResponseText)
        XCTAssertEqual(ReminderTiming.summary(viewModel.detail?.reminders ?? []), "하루 전 · 1시간 전")

        viewModel.openReminderEditor()
        viewModel.toggleReminder(.hourBefore)
        viewModel.toggleReminder(.tenMinutesBefore)
        await viewModel.saveReminders()

        XCTAssertEqual(viewModel.detail?.reminders, [.dayBefore, .tenMinutesBefore], "이른 순으로 저장")
        XCTAssertFalse(viewModel.isReminderEditorPresented)
    }

    // MARK: 07-10 ~ 07-12 내 활동

    func testActivitySummaryUsesLiveCounts() async {
        let viewModel = makeContainer().makeActivitySummaryViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.unreadNotificationCount, 5, "알림 센터와 같은 안 읽은 알림 수")
        XCTAssertEqual(viewModel.state.value?.submittedDocumentCount, 6, "임시 저장은 빼고 센 내 결재")
        XCTAssertEqual(viewModel.state.value?.postCount, 3)
    }

    func testMyPostsTabsAndTexts() async {
        let viewModel = makeContainer().makeMyPostsViewModel(userName: "옥물결")

        await viewModel.load()

        XCTAssertEqual(viewModel.title(for: .posts), "글 3")
        XCTAssertEqual(viewModel.title(for: .comments), "댓글 4")
        XCTAssertEqual(viewModel.posts.first?.title, "이번 주 함께 읽을 책 추천해요", "최근 글이 위로")
        XCTAssertEqual(viewModel.posts.first?.statsText, "좋아요 8 · 댓글 3 · 조회 41")
        XCTAssertEqual(viewModel.posts[1].statsText, "좋아요 12 · 댓글 6 · 공개 표시: 익명")
        XCTAssertEqual(viewModel.posts[2].statsText, "좋아요 5 · 댓글 2 · 첨부 1개")
        XCTAssertTrue(viewModel.posts[1].metaText(authorName: "옥물결").hasSuffix("나만 보는 익명 기록"))
        XCTAssertEqual(viewModel.comments.first?.quoteText, "“예약 기준이 정리되면 좋겠어요.”")
    }

    func testMyProposalsFilter() async {
        let viewModel = makeContainer().makeMyProposalsViewModel(userName: "옥물결")

        await viewModel.load()

        XCTAssertEqual(ProposalFilter.allCases.map { viewModel.count(of: $0) }, [3, 2, 1])
        XCTAssertEqual(viewModel.subtitle, "옥물결 님이 작성한 운영 제안 3개")
        viewModel.filter = .answered
        XCTAssertEqual(viewModel.proposals.map(\.title), ["집중 업무 시간을 캘린더에 표시해요"])
        XCTAssertEqual(viewModel.proposals.first?.linkTitle, "운영 답변 확인")
    }
}
