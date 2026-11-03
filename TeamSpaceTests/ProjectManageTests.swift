import XCTest
@testable import TeamSpace

/// 프로젝트 등록 · 수정 (POST · PATCH /admin/projects)
@MainActor
final class ProjectManageTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let pm = AuthUser(id: 2, name: "이시우", roles: [.pm, .leader])

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

    func testAdminRegistersProject() async throws {
        let container = makeContainer()
        let compose = container.makeProjectComposeViewModel(user: admin)
        XCTAssertEqual(compose.screenTitle, "프로젝트 등록")
        XCTAssertFalse(compose.canSubmit, "이름 · PM 이 없으면 못 보내요")

        compose.draft.name = "  Green Note  "
        compose.draft.summary = "그린랩 메모 앱"
        compose.draft.department = "Dev"
        compose.draft.pmName = "안율"
        compose.draft.status = .planned
        compose.draft.startDate = date(8, 1)
        compose.draft.endDate = date(11, 20)
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertTrue(compose.didSave)
        XCTAssertEqual(compose.savedProjectId, "green-note")

        let detail = container.makeProjectDetailViewModel(projectId: "green-note")
        await detail.load()
        let project = try XCTUnwrap(detail.detail?.project)
        XCTAssertEqual(project.name, "Green Note")
        XCTAssertEqual(project.summary, "그린랩 메모 앱")
        XCTAssertEqual(project.department, "Dev")
        XCTAssertEqual(project.pmName, "안율")
        XCTAssertEqual(project.status, .planned)
        XCTAssertEqual(project.startDate, date(8, 1))
        XCTAssertEqual(project.endDate, date(11, 20), "마감일까지 그대로")
    }

    func testAdminEditsProjectKeepingMembers() async throws {
        let container = makeContainer()
        let before = container.makeProjectDetailViewModel(projectId: "book-on")
        await before.load()
        let original = try XCTUnwrap(before.detail)

        let compose = container.makeProjectComposeViewModel(user: admin, editing: original.project)
        XCTAssertTrue(compose.isEditing)
        XCTAssertEqual(compose.submitTitle, "수정 완료")
        XCTAssertEqual(compose.draft.name, "Book-on")
        XCTAssertEqual(compose.draft.pmName, "이시우")
        XCTAssertEqual(compose.draft.progress, 68)

        compose.draft.summary = "독서 기록 · 습관 앱"
        compose.draft.progress = 75
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertEqual(compose.completionTitle, "프로젝트를 수정했어요")

        let after = container.makeProjectDetailViewModel(projectId: "book-on")
        await after.load()
        let updated = try XCTUnwrap(after.detail)
        XCTAssertEqual(updated.project.summary, "독서 기록 · 습관 앱")
        XCTAssertEqual(updated.project.progress, 75)
        XCTAssertEqual(updated.members.count, original.members.count, "참여자는 그대로")
        XCTAssertEqual(updated.project.openings.count, original.project.openings.count, "모집 자리도 그대로")
    }

    func testCompletedProjectSavesFullProgress() async throws {
        let container = makeContainer()
        let compose = container.makeProjectComposeViewModel(user: admin)
        compose.draft.name = "회고 정리"
        compose.draft.pmName = "오잉"
        compose.draft.status = .completed
        compose.draft.progress = 40
        XCTAssertTrue(compose.isProgressLocked)
        await compose.submit()

        let detail = container.makeProjectDetailViewModel(projectId: try XCTUnwrap(compose.savedProjectId))
        await detail.load()
        XCTAssertEqual(detail.detail?.project.progress, 100)
        XCTAssertEqual(detail.detail?.project.status, .completed)
    }

    func testPeriodAndPermissionChecks() async {
        let container = makeContainer()
        let compose = container.makeProjectComposeViewModel(user: admin)
        compose.draft.name = "기간 확인"
        compose.draft.pmName = "오잉"
        compose.draft.startDate = date(9, 1)
        compose.draft.endDate = date(8, 1)
        XCTAssertEqual(compose.periodHint, "끝나는 날은 시작일보다 뒤로 정해 주세요.")
        XCTAssertFalse(compose.canSubmit)

        XCTAssertFalse(pm.can(.registerProjects), "PM · Leader 도 서버 require_admin 이라 못 해요")
        let byPM = container.makeProjectComposeViewModel(user: pm)
        byPM.draft.name = "권한 확인"
        byPM.draft.pmName = "이시우"
        await byPM.submit()
        XCTAssertFalse(byPM.didSave)
        XCTAssertEqual(byPM.errorMessage, "프로젝트는 관리자만 등록할 수 있어요.")
    }

    func testWriteRequestShape() throws {
        var draft = ProjectDraft()
        draft.name = "Book-on"
        draft.summary = "독서 기록 앱"
        draft.department = "NativeLab"
        draft.pmName = "이시우"
        draft.status = .inProgress
        draft.progress = 60
        draft.startDate = date(7, 1)
        draft.endDate = date(11, 30)
        let dto = ServerProjectWriteRequestDTO(draft)
        let year = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(dto.desc, "독서 기록 앱 · \(year).07 – \(year).11")
        XCTAssertEqual(dto.due, "11.30 마감")
        XCTAssertEqual(dto.status, "진행 중")
        let keys = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any]).keys.sorted()
        XCTAssertEqual(keys, ["dept", "desc", "due", "name", "pm", "progress", "status"], "참여자 · 모집은 보내지 않아요")
    }
}
