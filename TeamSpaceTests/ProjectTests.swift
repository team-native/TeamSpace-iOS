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

    // MARK: 14-2 검색 결과 없음 — 필터 초기화

    func testResetFiltersRestoresAllProjects() async {
        let viewModel = makeContainer().makeProjectListViewModel()
        await viewModel.load()
        XCTAssertFalse(viewModel.hasActiveFilters)

        viewModel.statusFilter = .completed
        viewModel.department = "NativeOps"
        viewModel.recruitingOnly = true
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertTrue(viewModel.projects.isEmpty)

        viewModel.resetFilters()
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.countText, "전체 프로젝트 5개")
    }

    // MARK: 07-18 프로젝트 목록

    func testWorkspaceProjectListTabs() async {
        let viewModel = makeContainer().makeWorkspaceProjectListViewModel()
        await viewModel.load()

        let total = viewModel.count(of: .all)
        XCTAssertGreaterThan(total, 0)
        XCTAssertEqual(viewModel.count(of: .recruiting), 2, "Book-on · Native 팀 가이드")

        viewModel.tab = .recruiting
        XCTAssertTrue(viewModel.projects.allSatisfy(\.isRecruiting))
        viewModel.tab = .inProgress
        XCTAssertTrue(viewModel.projects.allSatisfy { $0.status == .inProgress && !$0.isRecruiting })
        viewModel.tab = .completed
        XCTAssertEqual(viewModel.projects.map(\.name), ["Inspace 리서치"])
    }

    func testWorkspaceProjectListMetaText() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30))!
        let nov6 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6))!
        let oct22 = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22))!
        func project(status: ProjectRunStatus, end: Date, pm: String = "이시우", openings: [ProjectOpening] = []) -> ProjectSummary {
            ProjectSummary(
                id: "1", name: "학과 행사 웹페이지", summary: "", department: "NativeLab", pmName: pm, memberCount: 2,
                status: status, startDate: now, endDate: end, progress: 60, openings: openings, resultNote: nil, updatedAt: now
            )
        }
        let opening = { (role: String) in
            ProjectOpening(id: 1, role: role, title: role, headcount: 1, startDate: now, endDate: nov6, description: "")
        }

        XCTAssertEqual(project(status: .inProgress, end: nov6).listMetaText(now: now, calendar: calendar),
                       "PM 이시우 · NativeLab · 2명 · 마감 \(TSFormat.monthDay(nov6))")
        XCTAssertEqual(project(status: .completed, end: oct22).listMetaText(now: now, calendar: calendar),
                       "PM 이시우 · NativeLab · 2명 · \(TSFormat.monthDay(oct22)) 종료")
        XCTAssertEqual(project(status: .inProgress, end: nov6, pm: "").listMetaText(now: now.addingTimeInterval(-60 * 86_400), calendar: calendar),
                       "PM 모집 · NativeLab · 2명", "마감이 30일보다 많이 남으면 안 붙여요")

        let recruiting = project(status: .planned, end: nov6, pm: "옥물결", openings: [opening("디자인"), opening("개발")])
        XCTAssertEqual(recruiting.listMetaText(now: now, calendar: calendar), "PM 옥물결 · NativeLab · 팀원 2명 모집")
        XCTAssertEqual(recruiting.openingsNeedText, "디자인 1 · 개발 1 필요")
    }

    // MARK: 08-2 프로젝트 상세

    func testProjectDetail() async {
        let joined = makeContainer().makeProjectDetailViewModel(projectId: "book-on")
        await joined.load()
        XCTAssertEqual(joined.detail?.members.count, 6)
        XCTAssertEqual(joined.detail?.members.first?.role, "PM")
        XCTAssertEqual(joined.detail?.project.openings.first?.title, "iOS", "서버 모집 자리는 [직군, 설명] 이라 직군이 이름이에요")
        XCTAssertEqual(joined.detail?.project.openings.first?.description.hasSuffix("위젯 기능 개발과 출시 전 QA를 함께해요."), true)
        XCTAssertFalse(joined.canApply, "이미 참여 중이면 신청 버튼 대신 일정 보기")
        XCTAssertEqual(joined.detail?.project.summary, "독서 기록과 습관 만들기를 돕는 iOS 앱", "desc 끝의 기간은 따로 읽어요")
        XCTAssertNotNil(joined.detail?.project.startDate)
        XCTAssertEqual(joined.detail?.project.dueText?.hasSuffix("출시"), true)

        let planned = makeContainer().makeProjectDetailViewModel(projectId: "team-guide")
        await planned.load()
        XCTAssertTrue(planned.canApply)
        XCTAssertEqual(planned.detail?.project.status.badgeTitle, "예정")
    }

    // MARK: 08-8 일정과 변경 이력

    func testTimeline() async {
        let viewModel = makeContainer().makeProjectTimelineViewModel(projectId: "book-on")
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
        let joined = container.makeRecruitmentViewModel(projectId: "book-on")
        await joined.load()
        XCTAssertEqual(joined.post?.roleBadgeText, "iOS · 1명")
        XCTAssertEqual(joined.post?.canApply, false, "이미 참여 중인 프로젝트")
        XCTAssertEqual(joined.post?.applyButtonTitle, "이미 참여 중인 프로젝트예요")

        let viewModel = container.makeRecruitmentViewModel(projectId: "team-guide")
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
        let viewModel = makeContainer().makeApplicantReviewViewModel(projectId: "book-on")
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

/// 서버 `Project` 형식 읽기 (TeamSpace-backend `space.py`, 프런트 `PROJECTS`)
final class ProjectServerDTOTests: XCTestCase {
    func testFrontendShapeDecodes() throws {
        let json = Data(#"""
        {"id":"book-on","name":"Book-on","desc":"독서 기록 앱 · 그린랩 외주 · 2026.08 – 2026.11","role":"iOS 리드",
         "progress":68,"status":"진행 중","tone":"blue","due":"11.20 납품","milestone":"베타 배포 · 11.05","pm":"박도윤",
         "members":[["doyun","PM"],["junpyo","iOS 리드"]],
         "openings":[["Web 프론트엔드","1명 · 관리자 페이지 · 주 6시간"],["QA","2명 · 베타 테스트 · 11.01 – 11.15"]]}
        """#.utf8)

        let project = try JSONCoder.makeDecoder().decode(ServerProjectDTO.self, from: json).toEntity()

        XCTAssertEqual(project.id, "book-on")
        XCTAssertEqual(project.summary, "독서 기록 앱 · 그린랩 외주")
        XCTAssertEqual(project.status, .inProgress)
        XCTAssertEqual(project.memberCount, 2)
        XCTAssertEqual(project.dueText, "11.20 납품")
        let calendar = Calendar.current
        XCTAssertEqual(project.startDate.map { calendar.dateComponents([.year, .month], from: $0) }, DateComponents(year: 2026, month: 8))
        XCTAssertEqual(project.endDate.map { calendar.dateComponents([.year, .month, .day], from: $0) }, DateComponents(year: 2026, month: 11, day: 20))
        XCTAssertEqual(project.openings.map(\.role), ["Web 프론트엔드", "QA"])
        XCTAssertEqual(project.openings.map(\.headcount), [1, 2])
        XCTAssertEqual(project.openings[0].description, "관리자 페이지 · 주 6시간")
        XCTAssertNil(project.openings[0].startDate)
        XCTAssertNotNil(project.openings[1].startDate, "\"11.01 – 11.15\" 기간을 읽어요")
    }

    func testApplyRequestCarriesPosition() throws {
        let body = ServerApplyRequestDTO(ApplicationDraft(openingId: 1, position: "iOS 개발", availability: .tenHours, message: "안녕하세요"))
        let json = String(decoding: try JSONEncoder().encode(body), as: UTF8.self)
        XCTAssertTrue(json.contains(#""position":"iOS 개발""#), "서버는 position 이 없으면 400")
    }
}
