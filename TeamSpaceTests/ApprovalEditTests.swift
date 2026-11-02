import XCTest
@testable import TeamSpace

/// 05-3 결재 수정 · 07-5 이어서 작성 — PATCH /approvals/{id}
@MainActor
final class ApprovalEditTests: XCTestCase {
    /// 같은 Mock 서버를 쓰는 컨테이너 · 저장소
    private var repository: ApprovalRepository!

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        repository = ApprovalRepositoryImpl(client: client)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func detail(_ id: Int, in container: DIContainer) async throws -> ApprovalDetail {
        let viewModel = container.makeApprovalDetailViewModel(documentId: id)
        await viewModel.load()
        return try XCTUnwrap(viewModel.detail)
    }

    func testEditRulesFollowServer() async throws {
        let container = makeContainer()
        let draft = try await detail(2, in: container)
        XCTAssertTrue(draft.canEdit)
        XCTAssertTrue(draft.canWithdraw)

        let rejected = try await detail(3, in: container)
        XCTAssertTrue(rejected.canEdit, "반려되면 고쳐서 다시 올릴 수 있어요")
        XCTAssertFalse(rejected.canWithdraw, "반려된 결재는 취소할 수 없어요")

        let approved = try await detail(4, in: container)
        XCTAssertFalse(approved.canEdit)
        XCTAssertFalse(approved.canWithdraw)
    }

    /// 반려된 비용 결재를 기존 내용으로 채워 고친 뒤 다시 올리면, 새 결재 없이 같은 결재가 '검토 중'이 돼요.
    func testResubmitRejectedExpenseKeepsSameDocument() async throws {
        let container = makeContainer()
        let rejected = try await detail(3, in: container)
        let before = try await repository.fetchMyApprovals().count

        let viewModel = container.makeExpenseRequestViewModel()
        viewModel.prefill(from: rejected)
        XCTAssertEqual(viewModel.documentId, 3)
        XCTAssertEqual(viewModel.content, "외부 강사 섭외비")
        XCTAssertEqual(viewModel.amount, 300_000)
        XCTAssertEqual(viewModel.expenseType, .purchase)
        XCTAssertEqual(viewModel.project, "NativeLab")
        XCTAssertEqual(TSFormat.fullDate(viewModel.useDate), "2026.10.20")
        XCTAssertEqual(viewModel.reason, rejected.reason)

        viewModel.updateAmount("250000")
        viewModel.reason = "인원별 산출 근거를 보완했어요."
        let submitted = await viewModel.submit()

        XCTAssertEqual(submitted?.documentId, 3)
        XCTAssertNil(viewModel.errorMessage)
        let after = try await detail(3, in: container)
        XCTAssertEqual(after.item.status, .reviewing)
        XCTAssertEqual(after.item.amount, 250_000)
        XCTAssertEqual(after.reason, "인원별 산출 근거를 보완했어요.")
        XCTAssertEqual(after.approvers.first?.status, .reviewing, "결재선을 처음부터 다시 만들어요")
        let count = try await repository.fetchMyApprovals().count
        XCTAssertEqual(count, before, "새 결재가 생기지 않아요")
    }

    /// 임시 저장 문서를 이어서 작성하고 다시 임시 저장하면 같은 문서가 고쳐져요.
    func testResumeDraftSavesSameDocument() async throws {
        let container = makeContainer()
        let created = try await SubmitDocumentUseCase(approvalRepository: repository)
            .saveDraft(DocumentDraft(
                kind: .projectRequest, title: "Book-on 일정 변경 요청", amount: nil,
                fields: [
                    ApprovalField(title: "프로젝트", value: "Book-on"),
                    ApprovalField(title: "요청 종류", value: "일정 변경"),
                    ApprovalField(title: "필요 인원", value: "-"),
                    ApprovalField(title: "기간", value: "11.10 – 11.20"),
                    ApprovalField(title: "희망 반영일", value: "2026.11.10")
                ],
                reason: "QA 기간을 늘려요.", attachmentNames: []
            ))
        let draft = try await detail(created, in: container)

        let viewModel = container.makeRequestFormViewModel(kind: .project)
        viewModel.prefill(from: draft)
        XCTAssertEqual(viewModel.target, "Book-on")
        XCTAssertEqual(viewModel.category, "일정 변경")
        XCTAssertEqual(viewModel.quantity, "", "\"-\" 는 빈 값으로 읽어요")
        XCTAssertEqual(viewModel.period, "11.10 – 11.20")
        XCTAssertEqual(TSFormat.fullDate(viewModel.desiredDate), "2026.11.10")
        XCTAssertEqual(viewModel.body, "QA 기간을 늘려요.")

        viewModel.category = "예산"
        let saved = await viewModel.saveDraft()

        XCTAssertTrue(saved)
        let after = try await detail(created, in: container)
        XCTAssertEqual(after.item.status, .draft)
        XCTAssertEqual(after.item.title, "Book-on 예산 요청")
        XCTAssertEqual(after.fieldValue("요청 종류"), "예산")
    }

    func testStaffingPrefillReadsPeriodAndHeadcount() async throws {
        let container = makeContainer()
        let id = try await SubmitDocumentUseCase(approvalRepository: repository)
            .saveDraft(DocumentDraft(
                kind: .staffing, title: "MoSS 프로젝트 인력 지원", amount: nil,
                fields: [
                    ApprovalField(title: "프로젝트", value: "MoSS"),
                    ApprovalField(title: "필요 직군", value: "BE"),
                    ApprovalField(title: "인원", value: "3명"),
                    ApprovalField(title: "투입 기간", value: "2027.01 ~ 2027.03")
                ],
                reason: "API 작업", attachmentNames: []
            ))

        let viewModel = container.makeStaffingRequestViewModel()
        viewModel.prefill(from: try await detail(id, in: container))

        XCTAssertEqual(viewModel.project, "MoSS")
        XCTAssertEqual(viewModel.role, .backend)
        XCTAssertEqual(viewModel.headcount, 3)
        XCTAssertEqual(viewModel.draft.fields.last?.value, "2027.01 ~ 2027.03")
        let submitted = await viewModel.submit()
        XCTAssertEqual(submitted?.documentId, id)
    }

    func testPatchBodyHasNoKindAndServerRejectsReviewing() async throws {
        let draft = DocumentDraft(kind: .expense, title: "t", amount: 1, fields: [], reason: "r", attachmentNames: [])
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ServerApprovalCreateRequestDTO(draft, submit: true).patch)) as? [String: Any]
        XCTAssertNil(body?["kind"], "서버 ApprovalPatch 는 kind 를 받지 않아요")
        XCTAssertNil(body?["files"])
        XCTAssertEqual(body?["status"] as? String, "결재 대기")

        _ = makeContainer()
        do {
            _ = try await repository.updateDocument(documentId: 1, draft, submit: true)
            XCTFail("검토 중인 결재는 고칠 수 없어요")
        } catch {
            XCTAssertFalse(error.userMessage.isEmpty)
        }
    }
}
