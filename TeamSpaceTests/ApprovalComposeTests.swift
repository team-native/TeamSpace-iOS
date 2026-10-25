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
        XCTAssertEqual(detail.item.status, .pending, "제출하면 결재 대기")
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
