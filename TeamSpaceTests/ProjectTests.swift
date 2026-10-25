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
}
