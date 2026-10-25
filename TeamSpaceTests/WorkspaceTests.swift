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
}
