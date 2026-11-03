import XCTest
@testable import TeamSpace

/// 재정 열람 권한 관리 (GET · PATCH /admin/finance/permissions)
@MainActor
final class FinancePermissionManageTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let fa = AuthUser(id: 5, name: "이시우", roles: [.fa])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testListSortsViewersFirst() async throws {
        let viewModel = makeContainer().makeFinancePermissionViewModel(user: admin)
        await viewModel.load()

        XCTAssertEqual(viewModel.members.map(\.name), ["관리자", "김민준", "이시우", "양지우", "옥물결", "홍길동"], "열람 가능 먼저, 이름순")
        XCTAssertEqual(viewModel.summaryText, "열람 가능 3명 · 전체 6명")
        let leader = try XCTUnwrap(viewModel.members.first { $0.name == "김민준" })
        XCTAssertTrue(leader.isLockedByRole)
        XCTAssertEqual(leader.lockNote, "Leader · Admin 역할이라 늘 볼 수 있어요")
        XCTAssertEqual(viewModel.members.first { $0.name == "이시우" }?.roleText, "FA · PM")
        XCTAssertEqual(viewModel.members.first { $0.name == "옥물결" }?.roleText, "구성원")

        viewModel.query = "s26011"
        XCTAssertEqual(viewModel.members.map(\.name), ["옥물결"], "이메일로도 찾아요")
    }

    func testGrantAndRevoke() async throws {
        let container = makeContainer()
        let viewModel = container.makeFinancePermissionViewModel(user: admin)
        await viewModel.load()
        let member = try XCTUnwrap(viewModel.members.first { $0.name == "옥물결" })

        await viewModel.setCanViewFinance(member, to: true)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.toastMessage, "옥물결님에게 재정 열람 권한을 줬어요")
        let granted = try XCTUnwrap(viewModel.members.first { $0.id == member.id })
        XCTAssertTrue(granted.canViewFinance)
        XCTAssertEqual(granted.roles, [.fa, .member], "서버처럼 FA 가 더해져요")
        XCTAssertEqual(viewModel.summaryText, "열람 가능 4명 · 전체 6명")

        await viewModel.setCanViewFinance(granted, to: false)
        XCTAssertEqual(viewModel.toastMessage, "옥물결님의 재정 열람 권한을 회수했어요")
        XCTAssertEqual(viewModel.members.first { $0.id == member.id }?.roles, [.member])

        let reloaded = container.makeFinancePermissionViewModel(user: admin)
        await reloaded.load()
        XCTAssertEqual(reloaded.members.first { $0.id == member.id }?.canViewFinance, false, "서버에 남아요")
    }

    func testCannotRevokeLeader() async throws {
        let viewModel = makeContainer().makeFinancePermissionViewModel(user: admin)
        await viewModel.load()
        let leader = try XCTUnwrap(viewModel.members.first { $0.name == "김민준" })
        await viewModel.setCanViewFinance(leader, to: false)
        XCTAssertEqual(viewModel.errorMessage, "Leader · Admin 역할은 재정 정보를 계속 볼 수 있어요.")
        XCTAssertEqual(viewModel.members.first { $0.id == leader.id }?.canViewFinance, true)
    }

    func testOnlyAdminManagesPermissions() async {
        XCTAssertFalse(fa.can(.manageFinancePermissions), "FA 도 서버 require_admin 이라 못 바꿔요")
        let viewModel = makeContainer().makeFinancePermissionViewModel(user: fa)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("권한 없음 화면이어야 해요") }
    }

    func testRequestBody() throws {
        let body = try JSONEncoder().encode(ServerFinancePermissionRequestDTO(canViewFinance: true))
        XCTAssertEqual(String(decoding: body, as: UTF8.self), #"{"canViewFinance":true}"#)
    }
}
