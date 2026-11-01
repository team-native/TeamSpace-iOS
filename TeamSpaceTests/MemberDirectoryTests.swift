import XCTest
@testable import TeamSpace

@MainActor
final class MemberDirectoryTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testListShowsEightThenMore() async {
        let viewModel = makeContainer().makeMemberDirectoryViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.summary, "Native 24명 · 5개 부서")
        XCTAssertEqual(viewModel.visibleMembers.count, 8)
        XCTAssertEqual(viewModel.hiddenCount, 16, "Figma: 16명 더 보기")
        XCTAssertEqual(viewModel.visibleMembers.first?.department, .leader, "Leader 가 맨 위")

        viewModel.isExpanded = true
        XCTAssertEqual(viewModel.visibleMembers.count, 24)
        XCTAssertEqual(viewModel.hiddenCount, 0)
    }

    func testSearchByNamePositionAndDepartment() async {
        let viewModel = makeContainer().makeMemberDirectoryViewModel()
        await viewModel.load()

        viewModel.query = "오잉"
        XCTAssertEqual(viewModel.filteredMembers.map(\.name), ["오잉"])

        viewModel.query = "ios"
        XCTAssertTrue(viewModel.filteredMembers.allSatisfy { $0.position.lowercased().contains("ios") })

        viewModel.query = "없는사람"
        XCTAssertTrue(viewModel.filteredMembers.isEmpty)
    }

    func testDepartmentFilterAndNewMember() async {
        let viewModel = makeContainer().makeMemberDirectoryViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.newMember()?.name, "카피바라", "이번 주 합류한 멤버")

        viewModel.departmentFilter = .department(.fa)
        XCTAssertEqual(viewModel.filteredMembers.map(\.name), ["김민준"])
    }

    func testOrganizationTapMovesToFilteredList() async throws {
        let viewModel = makeContainer().makeMemberDirectoryViewModel()
        await viewModel.load()
        viewModel.mode = .organization

        await viewModel.loadOrganizationIfNeeded()

        let tree = try XCTUnwrap(viewModel.organizationState.value)
        XCTAssertEqual(tree.leader.name, "이시우")
        XCTAssertEqual(tree.units.map(\.name).first, "NativeOps")
        XCTAssertEqual(tree.units.reduce(0) { $0 + $1.members.count }, 23)

        viewModel.showMembers(of: .design)
        XCTAssertEqual(viewModel.mode, .list)
        XCTAssertTrue(viewModel.filteredMembers.allSatisfy { $0.department == .design })
    }

    func testMemberDetailFromFigmaSample() async throws {
        let viewModel = makeContainer().makeMemberDetailViewModel(memberId: 4)

        await viewModel.load()

        let detail = try XCTUnwrap(viewModel.state.value)
        XCTAssertEqual(detail.member.name, "오잉")
        XCTAssertEqual(detail.email, "s26099@gsm.hs.kr")
        XCTAssertEqual(detail.projects.map(\.status), [.inProgress, .inProgress, .completed])
        XCTAssertEqual(viewModel.joinedText(detail), "2026년 3월 · 2기")
    }

    func testUnknownMemberShowsError() async {
        let viewModel = makeContainer().makeMemberDetailViewModel(memberId: 999)

        await viewModel.load()

        guard case .failed(let error) = viewModel.state, case .notFound = error as? AppError else {
            return XCTFail("없는 팀원은 404 오류여야 해요: \(viewModel.state)")
        }
    }
}
