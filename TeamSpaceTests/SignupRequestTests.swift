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
        await viewModel.startApproval(try XCTUnwrap(viewModel.requests.first))
        XCTAssertTrue(viewModel.canApprove, "비워 두면 요청할 때 정한 비밀번호를 써요")

        await viewModel.approve()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.approvingRequest, "시트를 닫아요")
        XCTAssertEqual(viewModel.toastMessage, "유다인님 계정을 만들어 조직도와 연결했어요")
        XCTAssertEqual(viewModel.requests.map(\.name), ["조현우"])
        XCTAssertEqual(viewModel.count(of: .processed), 2)
    }

    func testTemporaryPasswordRules() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        let noPassword = try XCTUnwrap(viewModel.requests.first { $0.name == "조현우" })

        await viewModel.startApproval(noPassword)
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

    func testApprovalPreselectsOnlySameNameUnlinkedMember() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()

        await viewModel.startApproval(try XCTUnwrap(viewModel.requests.first { $0.name == "유다인" }))
        XCTAssertEqual(viewModel.linkableMembers.map(\.name), ["유다인", "홍길동"], "계정이 없는 조직도 구성원만")
        XCTAssertEqual(viewModel.selectedMember?.name, "유다인", "같은 이름이 한 명이면 미리 골라요")

        await viewModel.startApproval(try XCTUnwrap(viewModel.requests.first { $0.name == "조현우" }))
        XCTAssertNil(viewModel.selectedMemberId, "이미 계정이 연결된 사람은 고르지 않아요")
        XCTAssertEqual(viewModel.selectedMemberText, "연결 안 함")
    }

    func testApproveWithoutLinkKeepsPlainMessage() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        await viewModel.startApproval(try XCTUnwrap(viewModel.requests.first { $0.name == "유다인" }))
        viewModel.selectedMemberId = nil

        await viewModel.approve()
        XCTAssertEqual(viewModel.toastMessage, "유다인님 계정을 만들었어요")
        XCTAssertEqual(viewModel.linkableMembers.count, 2, "연결하지 않았으면 후보에 그대로 남아요")
    }

    func testRejectNeedsReasonAndMovesToProcessed() async throws {
        let viewModel = makeContainer().makeSignupRequestListViewModel(user: admin)
        await viewModel.load()
        viewModel.startRejection(try XCTUnwrap(viewModel.requests.first { $0.name == "조현우" }))
        viewModel.rejectReason = "   "
        XCTAssertFalse(viewModel.canReject, "사유가 비면 반려할 수 없어요")

        viewModel.rejectReason = " 재학생 인증이 필요해요. "
        XCTAssertTrue(viewModel.canReject)
        await viewModel.reject()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.rejectingRequest, "시트를 닫아요")
        XCTAssertEqual(viewModel.toastMessage, "조현우님 요청을 반려했어요")
        XCTAssertEqual(viewModel.requests.map(\.name), ["유다인"])
        viewModel.filter = .processed
        let rejected = try XCTUnwrap(viewModel.requests.first { $0.name == "조현우" })
        XCTAssertEqual(rejected.status, .rejected)
        XCTAssertEqual(rejected.rejectionReason, "재학생 인증이 필요해요.")
        XCTAssertEqual(rejected.statusText, "반려 · 관리자")

        await viewModel.load()
        XCTAssertEqual(viewModel.requests.first { $0.name == "조현우" }?.rejectionReason, "재학생 인증이 필요해요.", "서버에도 반려로 남아요")
    }

    func testOnlyAdminRejectsSignups() async throws {
        let client = APIClient(
            baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: InMemoryTokenStorage()
        )
        let useCase = RejectSignupRequestUseCase(signupRequestRepository: SignupRequestRepositoryImpl(client: client))
        let request = SignupRequestItem(
            id: 2, name: "조현우", email: "a@b.c", department: "Dev", major: nil, cohort: nil, message: nil,
            status: .reviewing, requestedAt: nil, approvedBy: nil
        )
        do {
            _ = try await useCase.execute(request, reason: "사유", user: leader)
            XCTFail("리더는 반려할 수 없어요")
        } catch AppError.forbidden {
        }
    }

    func testApproveBodyCarriesMemberId() throws {
        let body = try JSONEncoder().encode(ServerSignupApproveRequestDTO(temporaryPassword: nil, memberId: "member-02"))
        XCTAssertEqual(String(decoding: body, as: UTF8.self), #"{"memberId":"member-02"}"#)
    }

    func testApproveBodyOmitsEmptyPassword() throws {
        let empty = try JSONEncoder().encode(ServerSignupApproveRequestDTO(temporaryPassword: nil))
        XCTAssertEqual(String(decoding: empty, as: UTF8.self), "{}")
    }
}
