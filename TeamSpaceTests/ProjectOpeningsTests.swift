import XCTest
@testable import TeamSpace

/// 프로젝트 모집 자리 관리 (PATCH /admin/projects/{id} openings)
@MainActor
final class ProjectOpeningsTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let pm = AuthUser(id: 2, name: "이시우", roles: [.pm])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func date(_ month: Int, _ day: Int) -> Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    func testLoadsCurrentOpenings() async throws {
        let viewModel = makeContainer().makeProjectOpeningsViewModel(projectId: "book-on", user: admin)
        await viewModel.load()

        XCTAssertEqual(viewModel.projectName, "Book-on")
        let opening = try XCTUnwrap(viewModel.openings.first)
        XCTAssertEqual(opening.role, "iOS")
        XCTAssertEqual(opening.headcount, 1)
        XCTAssertEqual(opening.description, "위젯 기능 개발과 출시 전 QA를 함께해요.", "설명 앞 기간은 빼요")
        XCTAssertEqual(opening.startDate, date(11, 1))
        XCTAssertEqual(viewModel.summaryText, "모집 중 1자리 · 1명")
        XCTAssertFalse(viewModel.canSave, "바꾼 게 없으면 저장하지 않아요")
    }

    func testAddOpeningAndSave() async throws {
        let container = makeContainer()
        let viewModel = container.makeProjectOpeningsViewModel(projectId: "bridge", user: admin)
        await viewModel.load()
        XCTAssertEqual(viewModel.summaryText, "모집 중인 자리가 없어요")

        viewModel.startAdding()
        XCTAssertTrue(viewModel.isEditingNew)
        XCTAssertFalse(viewModel.canApplyEditing, "직군이 있어야 해요")
        viewModel.editing?.role = "  Web  "
        viewModel.editing?.headcount = 2
        viewModel.editing?.startDate = date(11, 5)
        viewModel.editing?.endDate = date(11, 20)
        viewModel.editing?.description = "관리자 페이지 개발"
        viewModel.applyEditing()
        XCTAssertNil(viewModel.editing)
        XCTAssertEqual(viewModel.openings.first?.role, "Web")
        XCTAssertEqual(viewModel.summaryText, "모집 중 1자리 · 2명")

        await viewModel.save()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.didSave)

        let detail = container.makeProjectDetailViewModel(projectId: "bridge")
        await detail.load()
        let saved = try XCTUnwrap(detail.detail?.project.openings.first)
        XCTAssertEqual(saved.role, "Web")
        XCTAssertEqual(saved.headcount, 2)
        XCTAssertEqual(saved.startDate, date(11, 5))
        XCTAssertEqual(saved.endDate, date(11, 20))
        XCTAssertTrue(detail.detail?.project.isRecruiting == true, "목록에 모집 중으로 보여요")
    }

    func testEditAndCloseRecruitment() async throws {
        let container = makeContainer()
        let viewModel = container.makeProjectOpeningsViewModel(projectId: "book-on", user: admin)
        await viewModel.load()
        let opening = try XCTUnwrap(viewModel.openings.first)

        viewModel.startEditing(opening)
        XCTAssertFalse(viewModel.isEditingNew)
        viewModel.editing?.endDate = date(10, 1)
        XCTAssertEqual(viewModel.editingHint, "모집 마감일은 시작일보다 뒤로 정해 주세요.")
        XCTAssertFalse(viewModel.canApplyEditing)
        viewModel.editing?.endDate = date(12, 31)
        viewModel.editing?.headcount = 3
        viewModel.applyEditing()
        XCTAssertEqual(viewModel.openings.count, 1, "같은 자리를 바꿔요")
        XCTAssertEqual(viewModel.openings.first?.headcount, 3)

        viewModel.remove(try XCTUnwrap(viewModel.openings.first))
        XCTAssertEqual(viewModel.saveTitle, "모집 마감으로 저장")
        await viewModel.save()
        XCTAssertTrue(viewModel.didSave)

        let detail = container.makeProjectDetailViewModel(projectId: "book-on")
        await detail.load()
        XCTAssertEqual(detail.detail?.project.openings.count, 0, "자리를 모두 지우면 모집 마감")
        XCTAssertEqual(detail.detail?.members.count, 6, "참여자는 그대로")
    }

    func testOnlyAdminSaves() async throws {
        let viewModel = makeContainer().makeProjectOpeningsViewModel(projectId: "book-on", user: pm)
        await viewModel.load()
        XCTAssertFalse(viewModel.canManage)
        viewModel.remove(try XCTUnwrap(viewModel.openings.first))
        XCTAssertFalse(viewModel.canSave, "PM 은 저장 버튼이 꺼져 있어요")

        let useCase = UpdateProjectOpeningsUseCase(projectRepository: ProjectRepositoryImpl(client: APIClient(
            baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: InMemoryTokenStorage()
        )))
        do {
            try await useCase.execute(projectId: "book-on", [], user: pm)
            XCTFail("관리자만 바꿀 수 있어요")
        } catch {
            XCTAssertEqual(error.userMessage, "모집 자리는 관리자만 바꿀 수 있어요.")
        }
    }

    func testRequestShapeMatchesServerFilters() throws {
        var draft = OpeningDraft()
        draft.role = "iOS"
        draft.headcount = 2
        draft.startDate = date(11, 1)
        draft.endDate = date(11, 15)
        draft.description = "위젯 개발"
        let dto = ServerProjectOpeningsRequestDTO([draft])
        XCTAssertEqual(dto.openings, [.init(role: "iOS", title: "iOS", count: 2, period: "11.01 – 11.15", description: "위젯 개발")])
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any])
        XCTAssertEqual(object.keys.sorted(), ["openings"], "다른 항목은 보내지 않아 그대로예요")
    }
}
