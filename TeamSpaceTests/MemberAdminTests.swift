import XCTest
@testable import TeamSpace

/// 멤버 관리 [Admin] — GET /people · PATCH /admin/users/{id}(/roles) · POST · DELETE /admin/users
@MainActor
final class MemberAdminTests: XCTestCase {
    private let admin = AuthUser(id: 1, name: "이시우", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "양지우", roles: [.leader])

    private func makeViewModel(user: AuthUser? = nil) -> MemberAdminViewModel {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeMemberAdminViewModel(user: user ?? admin)
    }

    func testPeopleBecomeAccountsAndLinkCandidates() throws {
        let json = #"""
        {"items":[
          {"id":"member-02","name":"안율","email":"a@x.kr","dept":"NativeOps","roles":["Admin"],"active":true,"linked":true,"userId":"7"},
          {"id":"member-24","name":"홍길동","email":"","dept":"PMO","roles":["Member"],"active":true,"linked":false,"userId":null},
          {"id":"41","name":"새 팀원","email":"n@x.kr","dept":"Dev","roles":["PM"],"active":false,"linked":false,"userId":"41"}
        ],"nextCursor":null}
        """#
        let page = try JSONCoder.makeDecoder().decode(CursorPageDTO<ServerPersonDTO>.self, from: Data(json.utf8))
        let members = page.items.map { $0.toManagedMember() }

        XCTAssertEqual(members.map(\.id), ["7", "member-24", "41"], "관리 API 는 계정 id 로, 계정 없는 사람은 조직도 id")
        XCTAssertEqual(members.map(\.hasAccount), [true, false, true])
        XCTAssertEqual(members.map(\.isLinked), [true, false, false])
        XCTAssertEqual(members.map(\.organizationId), ["member-02", "member-24", nil])
        XCTAssertFalse(members[2].isActive)
        XCTAssertEqual(members[2].primaryRole, .pm)
    }

    func testListShowsAccountsAndSummary() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        XCTAssertEqual(viewModel.members.count, 22, "계정 없는 조직도 구성원 2명은 목록에서 빼요")
        XCTAssertEqual(viewModel.unlinkedOrganizationMembers.map(\.name), [], "Mock 의 계정 없는 사람은 숫자 id 라 조직도 후보가 아니에요")
        viewModel.query = "Design"
        XCTAssertTrue(viewModel.members.allSatisfy { $0.department == "Design" })
    }

    func testLeaderCannotOpen() async {
        let viewModel = makeViewModel(user: leader)
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("권한 없음 화면이어야 해요") }
    }

    func testChangeRoleDeptAndActive() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let member = try XCTUnwrap(viewModel.members.first { $0.name == "옥물결" })

        await viewModel.changeRole(member, to: .pm)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.members.first { $0.id == member.id }?.primaryRole, .pm)
        XCTAssertEqual(viewModel.toastMessage, "옥물결님 역할을 PM(으)로 바꿨어요")

        await viewModel.changeDepartment(member, to: "PMO")
        XCTAssertEqual(viewModel.members.first { $0.id == member.id }?.department, "PMO")

        await viewModel.setActive(member, to: false)
        XCTAssertEqual(viewModel.members.first { $0.id == member.id }?.isActive, false)
        XCTAssertEqual(viewModel.members.last?.name, "옥물결", "꺼진 계정은 아래로")
        XCTAssertTrue(viewModel.summaryText.contains("꺼짐 1명"))
    }

    func testLastAdminRoleShowsServerMessage() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let me = try XCTUnwrap(viewModel.members.first { $0.id == "1" })

        await viewModel.changeRole(me, to: .member)
        XCTAssertEqual(viewModel.errorMessage, "마지막 관리자 역할은 해제할 수 없습니다.")
        XCTAssertTrue(viewModel.isMe(me))
        await viewModel.setActive(me, to: false)
        XCTAssertEqual(viewModel.errorMessage, "내 계정은 끌 수 없어요.")
    }

    func testCreateShowsTemporaryPasswordOnce() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.startAdd()
        viewModel.draft.name = " 새 사람 "
        viewModel.draft.email = "bad-email"
        XCTAssertFalse(viewModel.canCreate)

        viewModel.draft.email = "New@gsm.hs.kr"
        viewModel.draft.department = "Dev"
        XCTAssertTrue(viewModel.canCreate)
        await viewModel.create()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAddPresented)
        XCTAssertEqual(viewModel.createdMember?.temporaryPassword, "mock-temp-Pw8x")
        XCTAssertEqual(viewModel.createdMember?.member.email, "new@gsm.hs.kr")
        XCTAssertTrue(viewModel.members.contains { $0.name == "새 사람" })
    }

    func testCreateDuplicateEmail() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.draft = NewMemberDraft(name: "중복", email: "taken@gsm.hs.kr", department: "", role: .member)
        await viewModel.create()
        XCTAssertEqual(viewModel.errorMessage, "이미 등록된 이메일입니다.")
        XCTAssertNil(viewModel.createdMember)
    }

    func testDeleteRemovesAndBlocksSelf() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let target = try XCTUnwrap(viewModel.members.first { $0.name == "홍길동" || $0.name == "옥물결" })

        await viewModel.delete(target)
        XCTAssertFalse(viewModel.members.contains { $0.id == target.id })
        XCTAssertEqual(viewModel.toastMessage, "\(target.name)님 계정을 삭제했어요")

        let me = try XCTUnwrap(viewModel.members.first { $0.id == "1" })
        await viewModel.delete(me)
        XCTAssertEqual(viewModel.errorMessage, "내 계정은 삭제할 수 없어요.")
    }

    func testLinkExistingAccountToOrganizationMember() async throws {
        let account = ManagedMember(
            id: "41", organizationId: nil, name: "홍길동", email: "h@x.kr", department: "PMO",
            roles: [.member], isActive: true, hasAccount: true, isLinked: false
        )
        let organization = ManagedMember(
            id: "member-24", organizationId: "member-24", name: "홍길동", email: "", department: "PMO",
            roles: [.member], isActive: true, hasAccount: false, isLinked: false
        )
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        let useCase = MemberAdminUseCase(repository: MemberAdminRepositoryImpl(client: client))

        let linked = try await useCase.link(account, to: organization, user: admin)
        XCTAssertTrue(linked.isLinked)
        XCTAssertEqual(linked.organizationId, "member-24")
        do {
            _ = try await useCase.link(linked, to: organization, user: admin)
            XCTFail("같은 구성원과는 다시 연결하지 않아요")
        } catch AppError.invalidInput {
        }
    }

    func testPatchBodyOnlyCarriesChangedFields() throws {
        let body = try JSONEncoder().encode(ServerAdminUserPatchDTO(memberId: "member-02"))
        XCTAssertEqual(String(decoding: body, as: UTF8.self), #"{"memberId":"member-02"}"#)
    }
}
