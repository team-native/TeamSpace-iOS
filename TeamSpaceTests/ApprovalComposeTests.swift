import XCTest
@testable import TeamSpace

@MainActor
final class ApprovalComposeTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 05-5 비용 승인 요청

    func testExpenseSubmitAppearsInMyApprovals() async throws {
        let container = makeContainer()
        let viewModel = container.makeExpenseRequestViewModel()
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.expenseType = .purchase
        viewModel.project = "Book-on"
        viewModel.content = "테스트용 iPad 구매"
        viewModel.updateAmount("1,200,000원")
        viewModel.reason = "태블릿 레이아웃 QA 가 필요해요."
        XCTAssertEqual(viewModel.formattedAmount, "1,200,000")
        XCTAssertTrue(viewModel.canSubmit)

        let submitted = await viewModel.submit()
        let result = try XCTUnwrap(submitted)
        XCTAssertEqual(result.firstApproverName, "안율")

        let detail = try await container.fetchApprovalDetailUseCase.execute(documentId: result.documentId)
        XCTAssertEqual(detail.item.status, .reviewing, "서버는 제출하면 결재선을 만들고 바로 검토 중")
        XCTAssertEqual(detail.item.amount, 1_200_000)
        XCTAssertEqual(detail.fields.first?.value, "물품 구매")
    }

    func testExpenseDraftIsSavedAsDraft() async throws {
        let container = makeContainer()
        let viewModel = container.makeExpenseRequestViewModel()
        viewModel.content = "워크숍 간식"

        let saved = await viewModel.saveDraft()

        XCTAssertTrue(saved)
        let box = try await container.fetchApprovalBoxUseCase.execute()
        XCTAssertEqual(box.mine.first { $0.title == "워크숍 간식" }?.status, .draft)
    }

    func testServerCreateRequestBody() throws {
        let staffing = DocumentDraft(
            kind: .staffing, title: "Book-on 프로젝트 인력 지원", amount: nil,
            fields: [
                ApprovalField(title: "프로젝트", value: "Book-on"),
                ApprovalField(title: "필요 직군", value: "Design"),
                ApprovalField(title: "인원", value: "2명"),
                ApprovalField(title: "투입 기간", value: "2026.11 ~ 2026.12")
            ],
            reason: "QA", attachmentNames: ["a.pdf"]
        )
        let body = ServerApprovalCreateRequestDTO(staffing, submit: true)
        XCTAssertEqual(body.kind, "인력 지원")
        XCTAssertEqual(body.status, "결재 대기")
        XCTAssertEqual(body.staff, ["Design": 2], "서버는 staff 로 인원을 받아요")
        XCTAssertEqual(body.project, "Book-on")
        XCTAssertEqual(body.period, "2026.11 ~ 2026.12")
        XCTAssertEqual(body.files, [], "첨부는 업로드 ID 가 생기면 보내요")
        XCTAssertEqual(body.details.fields.map(\.title), ["프로젝트", "필요 직군", "인원", "투입 기간"])

        let operation = DocumentDraft(
            kind: .operationRequest, title: "화이트보드", amount: 180_000,
            fields: [ApprovalField(title: "요청 분류", value: "물품 · 시설"), ApprovalField(title: "수량", value: "-")],
            reason: "필요해요", attachmentNames: []
        )
        let draft = ServerApprovalCreateRequestDTO(operation, submit: false)
        XCTAssertEqual(draft.kind, "운영 요청")
        XCTAssertEqual(draft.status, "작성 중")
        XCTAssertEqual(draft.type, "물품 · 시설")
        XCTAssertEqual(draft.amount, 180_000)
        XCTAssertEqual(draft.staff, [:])
    }

    func testSubmitValidation() {
        let draft = DocumentDraft(kind: .expense, title: "구매", amount: 0, fields: [], reason: "이유", attachmentNames: [])
        XCTAssertEqual(SubmitDocumentUseCase.validationMessage(for: draft), "요청 금액을 입력해 주세요.")
    }

    // MARK: 05-6 프로젝트 인력 지원

    func testStaffingSubmit() async throws {
        let container = makeContainer()
        let viewModel = container.makeStaffingRequestViewModel()
        viewModel.role = .design
        viewModel.changeHeadcount(by: 1)
        viewModel.changeHeadcount(by: -5)
        XCTAssertEqual(viewModel.draft.fields[2].value, "1명", "1명 아래로는 내려가지 않아요")
        viewModel.changeHeadcount(by: 1)
        viewModel.reason = "디자인 QA 인력이 필요해요."

        let submitted = await viewModel.submit()
        let result = try XCTUnwrap(submitted)

        let detail = try await container.fetchApprovalDetailUseCase.execute(documentId: result.documentId)
        XCTAssertEqual(detail.item.kind, .staffing)
        XCTAssertEqual(detail.fields.map(\.value)[1...2], ["Design", "2명"])
    }
}

@MainActor
final class RequestFormTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 05-12 프로젝트 관련 요청서

    func testProjectRequestSubmit() async throws {
        let container = makeContainer()
        let viewModel = container.makeRequestFormViewModel(kind: .project)
        XCTAssertEqual(viewModel.category, "인원 조정", "첫 번째 칩이 기본 선택")
        viewModel.quantity = "QA 1명"
        viewModel.period = "10.23 – 10.31"
        viewModel.body = "QA 일정에 맞춰 테스트 인원이 더 필요해요."

        let submitted = await viewModel.submit()
        let result = try XCTUnwrap(submitted)

        XCTAssertEqual(result.firstApproverName, "이시우")
        let detail = try await container.fetchApprovalDetailUseCase.execute(documentId: result.documentId)
        XCTAssertEqual(detail.item.kind, .projectRequest)
        XCTAssertEqual(detail.item.title, "Book-on 인원 조정 요청")
        XCTAssertEqual(detail.fields.first { $0.title == "필요 인원" }?.value, "QA 1명")
    }

    // MARK: 05-13 운영 관련 요청서

    func testOperationRequestKeepsAmount() async throws {
        let container = makeContainer()
        let viewModel = container.makeRequestFormViewModel(kind: .operation)
        viewModel.category = "물품 · 시설"
        viewModel.updateAmount("180000")
        viewModel.quantity = "2개"
        viewModel.body = "4층 플레이스에 화이트보드 2개가 필요해요."

        XCTAssertEqual(viewModel.formattedAmount, "180,000")
        let submitted = await viewModel.submit()
        let result = try XCTUnwrap(submitted)

        let detail = try await container.fetchApprovalDetailUseCase.execute(documentId: result.documentId)
        XCTAssertEqual(detail.item.amount, 180_000)
        XCTAssertEqual(detail.item.kind, .operationRequest)
    }

    // MARK: 05-11 기타 내부 문서

    func testEtcDocumentNeedsTitleAndBody() async {
        let viewModel = makeContainer().makeRequestFormViewModel(kind: .etc)
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.title = "10월 외주 회고 정리 공유 건"
        viewModel.body = "이번 달 외주 프로젝트 회고를 정리해 공유드려요."

        XCTAssertTrue(viewModel.canSubmit)
        XCTAssertEqual(viewModel.kind.approvalLine.count, 2, "기타 문서는 1차 · 2차 결재")
        let saved = await viewModel.saveDraft()
        XCTAssertTrue(saved)
    }
}
