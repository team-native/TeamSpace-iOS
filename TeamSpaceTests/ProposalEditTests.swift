import XCTest
@testable import TeamSpace

/// 12-2b 내 운영 제안 고치기 · 지우기 — PATCH · DELETE /proposals/{id}
@MainActor
final class ProposalEditTests: XCTestCase {
    private let member = AuthUser(id: 3, name: "옥물결", roles: [.member])
    private let admin = AuthUser(id: 1, name: "이시우", roles: [.admin])

    private func makeContainer(defaultsName: String = #function) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        let defaults = UserDefaults(suiteName: "test.proposal.edit.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsProposalDraftRepository.key)
        return DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            proposalDraftRepository: UserDefaultsProposalDraftRepository(defaults: defaults)
        )
    }

    /// 접수 상태의 내 제안을 하나 올려요.
    private func postProposal(_ container: DIContainer) async throws -> Int {
        let compose = container.makeProposalComposeViewModel()
        compose.draft = ProposalDraft(department: "PMO", title: "처음 제목", body: "처음 내용", isAnonymous: true)
        await compose.submit()
        return try XCTUnwrap(compose.published?.id)
    }

    func testEditMyReceivedProposal() async throws {
        let container = makeContainer()
        let id = try await postProposal(container)
        let viewModel = container.makeProposalDetailViewModel(proposalId: id, user: member)
        await viewModel.load()

        XCTAssertTrue(viewModel.canEdit)
        XCTAssertTrue(viewModel.canDelete)
        viewModel.startEditing()
        XCTAssertEqual(viewModel.editDraft?.department, "PMO")
        XCTAssertEqual(viewModel.editDraft?.body, "처음 내용")

        viewModel.editDraft?.title = "  "
        XCTAssertFalse(viewModel.canSaveEdit, "빈 제목은 저장 못 해요")
        viewModel.editDraft?.title = " 고친 제목 "
        viewModel.editDraft?.department = "FA"
        await viewModel.saveEdit()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.editDraft, "저장하면 시트를 닫아요")
        XCTAssertEqual(viewModel.detail?.proposal.title, "고친 제목")
        XCTAssertEqual(viewModel.detail?.proposal.department, "FA")
        XCTAssertEqual(viewModel.detail?.proposal.isAnonymous, true, "익명 여부는 그대로")
        XCTAssertEqual(viewModel.toastMessage, "제안을 고쳤어요")
    }

    func testPMOIsSentAsServerDepartment() throws {
        XCTAssertEqual(ProposalDraft.serverDepartment("PMO"), "PM / PO", "서버는 PMO 를 받지 않아요")
        XCTAssertEqual(ProposalDraft.serverDepartment("NativeOps"), "NativeOps")
        XCTAssertEqual(ProposalDraft.chipDepartment("PM / PO"), "PMO")
        XCTAssertEqual(ProposalDraft.chipDepartment("Design & Client"), "Design")
    }

    func testReviewedProposalCannotBeEdited() async {
        let container = makeContainer()
        // 12 · 11 · 9 는 내 제안이지만 이미 검토 중 · 답변 완료예요.
        let viewModel = container.makeProposalDetailViewModel(proposalId: 11, user: member)
        await viewModel.load()
        XCTAssertFalse(viewModel.canEdit)
        XCTAssertTrue(viewModel.canDelete, "지우기는 상태와 상관없어요")
        viewModel.startEditing()
        XCTAssertNil(viewModel.editDraft)
    }

    func testOthersProposalHidesMenuUnlessAdmin() async {
        let container = makeContainer()
        let asMember = container.makeProposalDetailViewModel(proposalId: 15, user: member)
        await asMember.load()
        XCTAssertFalse(asMember.hasMoreMenu, "남의 제안은 더보기가 없어요")

        let asAdmin = container.makeProposalDetailViewModel(proposalId: 15, user: admin)
        await asAdmin.load()
        XCTAssertFalse(asAdmin.canEdit, "Admin 도 남의 제안 내용은 못 고쳐요")
        XCTAssertTrue(asAdmin.canDelete)
    }

    func testDeleteProposal() async throws {
        let container = makeContainer()
        let id = try await postProposal(container)
        let viewModel = container.makeProposalDetailViewModel(proposalId: id, user: member)
        await viewModel.load()
        await viewModel.delete()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isDeleted)

        let list = container.makeProposalListViewModel()
        await list.load()
        XCTAssertFalse(list.proposals.contains { $0.id == id }, "목록에서도 빠져요")
    }

    func testUseCaseBlocksOthers() async throws {
        let container = makeContainer()
        let viewModel = container.makeProposalDetailViewModel(proposalId: 15, user: member)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)
        let useCase = EditProposalUseCase(proposalRepository: ProposalRepositoryImpl(client: APIClient(
            baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: InMemoryTokenStorage()
        )))
        do {
            _ = try await useCase.update(detail, draft: EditProposalUseCase.draft(from: detail))
            XCTFail("남의 제안은 못 고쳐요")
        } catch AppError.forbidden {}
        do {
            try await useCase.delete(detail.proposal, user: member)
            XCTFail("남의 제안은 못 지워요")
        } catch AppError.forbidden {}
    }

    func testPatchBody() throws {
        let body = try JSONEncoder().encode(ServerProposalPatchRequestDTO(title: "t", body: "b", category: "PMO", dept: "PM / PO"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(object["anonymous"], "익명 여부는 보내지 않아요")
        XCTAssertEqual(object["dept"] as? String, "PM / PO")
    }
}
