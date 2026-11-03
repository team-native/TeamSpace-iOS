import XCTest
@testable import TeamSpace

/// 가입 요청 승인 (GET /admin/signup-requests · POST /admin/signup-requests/{id}/approve)
@MainActor
final class SignupRequestTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "김민준", roles: [.leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testListSplitsPendingAndProcessed() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()

        XCTAssertEqual(viewModel.requests.map(\.name), ["유다인", "조현우"], "검토 중, 최신순")
        XCTAssertEqual(viewModel.count(of: .pending), 2)
        XCTAssertEqual(viewModel.count(of: .processed), 1)
        let first = try XCTUnwrap(viewModel.requests.first)
        XCTAssertEqual(first.metaText, "Design · UI/UX · 9기")
        XCTAssertEqual(first.message, "디자인 시스템 작업에 함께하고 싶어요.")
        XCTAssertEqual(viewModel.requests.last?.metaText, "Dev · iOS", "빈 항목은 빼요")

        viewModel.filter = .processed
        XCTAssertEqual(viewModel.requests.first?.statusText, "승인 · 관리자")
    }

    func testApproveWithRequestedPassword() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        viewModel.startApproval(try XCTUnwrap(viewModel.requests.first))
        XCTAssertTrue(viewModel.canApprove, "비워 두면 요청할 때 정한 비밀번호를 써요")

        await viewModel.approve()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.approvingRequest, "시트를 닫아요")
        XCTAssertEqual(viewModel.toastMessage, "유다인님 계정을 만들었어요")
        XCTAssertEqual(viewModel.requests.map(\.name), ["조현우"])
        XCTAssertEqual(viewModel.count(of: .processed), 2)
    }

    func testTemporaryPasswordRules() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        let noPassword = try XCTUnwrap(viewModel.requests.first { $0.name == "조현우" })

        viewModel.startApproval(noPassword)
        await viewModel.approve()
        XCTAssertEqual(viewModel.errorMessage, "가입 요청에 비밀번호가 없으므로 초기 비밀번호가 필요합니다.", "서버 안내를 그대로 보여줘요")
        XCTAssertNotNil(viewModel.approvingRequest, "시트는 열어 둬요")

        viewModel.errorMessage = nil
        viewModel.temporaryPassword = "short"
        XCTAssertEqual(viewModel.passwordHint, "8자 이상으로 정해 주세요.")
        XCTAssertFalse(viewModel.canApprove)

        viewModel.temporaryPassword = "native2026!"
        await viewModel.approve()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.toastMessage, "조현우님 계정을 만들었어요")
    }

    func testNewAccountRequestAppearsForAdmin() async throws {
        let container = makeContainer()
        let request = container.makeAccountRequestViewModel()
        request.form = AccountRequestForm(name: "한서준", email: "s26030@gsm.hs.kr", department: .fa, password: "native2026")
        _ = await request.submit()

        let viewModel = container.makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        XCTAssertEqual(viewModel.requests.first?.name, "한서준")
        XCTAssertEqual(viewModel.requests.first?.department, "FA")
    }

    func testOnlyAdminApprovesSignups() async {
        XCTAssertFalse(leader.can(.approveSignups))
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: leader)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("권한 없음 화면이어야 해요") }
    }

    func testApproveBodyOmitsEmptyPassword() throws {
        let empty = try JSONEncoder().encode(ServerSignupApproveRequestDTO(temporaryPassword: nil))
        XCTAssertEqual(String(decoding: empty, as: UTF8.self), "{}")
    }
}
