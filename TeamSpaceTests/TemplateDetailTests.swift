import XCTest
@testable import TeamSpace

@MainActor
final class TemplateDetailTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let storage = InMemoryTokenStorage()
        return DIContainer(
            apiClient: APIClient(
                baseURL: MockTransport.baseURL,
                transport: MockTransport(latencyNanoseconds: 0),
                tokenStorage: storage
            ),
            tokenStorage: storage
        )
    }

    func testEveryListedTemplateOpensMatchingDetailAndForm() async throws {
        let container = makeContainer()
        let library = container.makeLibraryViewModel()
        await library.load()
        library.filter = .template
        let templates = library.filteredDocuments
        XCTAssertEqual(templates.count, 3)
        let expectedForms: [Int: ApprovalComposeKind] = [3: .expense, 7: .staffing, 10: .etcDocument]

        for document in templates {
            XCTAssertEqual(document.route, .templateDetail(id: document.id))
            let detail = container.makeTemplateDetailViewModel(templateId: document.id)
            await detail.load()
            let template = try XCTUnwrap(detail.state.value)
            XCTAssertEqual(template.title, document.title)
            XCTAssertFalse(template.fields.isEmpty)
            XCTAssertEqual(template.formKind.composeKind, expectedForms[document.id])
        }
    }

    func testSearchResultOpensTemplateDetail() async throws {
        let search = makeContainer().makeLibrarySearchViewModel()
        search.query = "품의서"
        await search.search()
        XCTAssertEqual(try XCTUnwrap(search.results.first).route, .templateDetail(id: 3))
    }

    func testBudgetTemplateFieldsAndSubmissionReachApprovalDetail() async throws {
        let container = makeContainer()
        let detail = container.makeTemplateDetailViewModel(templateId: 3)
        await detail.load()
        let template = try XCTUnwrap(detail.state.value)
        XCTAssertEqual(template.monthlyUsageCount, 12)
        XCTAssertEqual(template.fields.map(\.title), ["비용 유형", "요청 금액과 사용일", "요청 사유", "첨부"])
        XCTAssertTrue(template.description.contains("\n작성하면"))

        let form = container.makeExpenseRequestViewModel()
        form.expenseType = .purchase
        form.content = "팀 공용 장비 구매"
        form.amountText = "120000"
        form.reason = "앱 검증에 사용할 공용 장비"
        let result = await form.submit()
        let submitted = try XCTUnwrap(result)
        let approval = container.makeApprovalDetailViewModel(documentId: submitted.documentId)
        await approval.load()
        XCTAssertEqual(approval.detail?.item.title, "팀 공용 장비 구매")
        XCTAssertEqual(approval.detail?.item.amount, 120000)
    }

    func testSettlementFormStartsWithTemplateTitle() {
        let form = makeContainer().makeRequestFormViewModel(kind: .etc, initialTitle: "정산 요청서")
        XCTAssertEqual(form.documentTitle, "정산 요청서")
        XCTAssertFalse(form.canSubmit)
        form.body = "프로젝트 종료에 따른 정산을 요청합니다."
        XCTAssertTrue(form.canSubmit)
    }

    func testMissingTemplateShowsRecoverableFailure() async {
        let viewModel = makeContainer().makeTemplateDetailViewModel(templateId: 999)
        await viewModel.load()
        guard case .failed(let error) = viewModel.state else { return XCTFail("없는 템플릿은 실패 상태") }
        XCTAssertEqual(error as? AppError, .notFound("템플릿을 찾을 수 없어요"))
    }

    func testForbiddenTemplateDoesNotExposeContent() async {
        let viewModel = TemplateDetailViewModel(
            templateId: 3,
            fetchTemplateUseCase: FetchLibraryTemplateUseCase(libraryRepository: ForbiddenTemplateRepository())
        )
        await viewModel.load()
        guard case .forbidden = viewModel.state else { return XCTFail("403은 forbidden") }
        XCTAssertNil(viewModel.state.value)
    }

    func testUnknownFormDoesNotOpenAnUnrelatedApprovalForm() throws {
        let form = try JSONDecoder().decode(TemplateFormKind.self, from: Data(#""FUTURE_FORM""#.utf8))
        XCTAssertEqual(form, .unknown)
        XCTAssertNil(form.composeKind)
    }
}

private struct ForbiddenTemplateRepository: LibraryRepository {
    func fetchLibrary() async throws -> LibraryOverview { throw AppError.forbidden(nil) }
    func searchLibrary(keyword: String) async throws -> [LibraryDocument] { throw AppError.forbidden(nil) }
    func fetchTemplate(id: Int) async throws -> LibraryTemplate { throw AppError.forbidden(nil) }
}
