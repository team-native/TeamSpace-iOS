import XCTest
@testable import TeamSpace

/// 일정 추가 (POST /admin/events)
@MainActor
final class ScheduleComposeTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let fa = AuthUser(id: 2, name: "김민준", roles: [.fa])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    private func time(_ hour: Int, _ minute: Int = 0, on day: Date = Date()) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    func testAdminAddsScheduleAndCalendarShowsIt() async throws {
        let container = makeContainer()
        XCTAssertTrue(container.makeScheduleCalendarViewModel(user: admin).canAddSchedule)

        let compose = container.makeScheduleComposeViewModel(user: admin)
        XCTAssertFalse(compose.canSubmit, "제목이 없으면 등록할 수 없어요")
        compose.draft.title = "  분기 회고  "
        compose.draft.scope = .team
        compose.draft.startsAt = time(20)
        compose.draft.endsAt = time(21, 30)
        compose.draft.place = "3층 라운지"
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertTrue(compose.didCreate)

        let calendar = container.makeScheduleCalendarViewModel(user: admin)
        await calendar.load()
        let event = try XCTUnwrap(calendar.selectedEvents.first { $0.title == "분기 회고" }, "오늘 일정에 보여요")
        XCTAssertEqual(event.listMetaText, "20:00 – 21:30 · 3층 라운지")
    }

    func testOnlyAdminCanAddSchedule() async {
        let container = makeContainer()
        XCTAssertFalse(container.makeScheduleCalendarViewModel(user: fa).canAddSchedule, "FA 도 서버 require_admin 이라 버튼이 없어요")
        XCTAssertFalse(container.makeScheduleCalendarViewModel().canAddSchedule)

        let compose = container.makeScheduleComposeViewModel(user: fa)
        compose.draft.title = "회의"
        await compose.submit()
        XCTAssertFalse(compose.didCreate)
        XCTAssertEqual(compose.errorMessage, "일정은 관리자만 추가할 수 있어요.")
    }

    func testEndMustBeAfterStart() async {
        let compose = makeContainer().makeScheduleComposeViewModel(user: admin)
        compose.draft.title = "회의"
        compose.draft.startsAt = time(15)
        compose.draft.endsAt = time(15)
        XCTAssertEqual(compose.timeHint, "끝나는 시각은 시작 시각보다 뒤로 정해 주세요.")
        await compose.submit()
        XCTAssertFalse(compose.didCreate)
        XCTAssertEqual(compose.errorMessage, "끝나는 시각은 시작 시각보다 뒤로 정해 주세요.")
    }

    func testCreateRequestUsesServerFormat() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 7)))
        var draft = ScheduleDraft(date: day, calendar: calendar)
        draft.title = "회의"
        draft.scope = .project
        draft.endsAt = try XCTUnwrap(calendar.date(bySettingHour: 16, minute: 5, second: 0, of: day))
        draft.asksRSVP = false
        let dto = ServerEventCreateRequestDTO(draft, calendar: calendar)
        XCTAssertEqual(dto.date, "2026-11-07")
        XCTAssertEqual(dto.start, "14:00")
        XCTAssertEqual(dto.end, "16:05")
        XCTAssertEqual(dto.scope, "프로젝트")
        XCTAssertFalse(dto.rsvp)
    }

    // MARK: 일정 수정 (PATCH /admin/events/{id})

    func testEditFillsDraftFromDetail() async throws {
        let container = makeContainer()
        let detail = container.makeScheduleDetailViewModel(scheduleId: 2, user: admin)
        await detail.load()
        XCTAssertTrue(detail.canEdit)
        let loaded = try XCTUnwrap(detail.detail)

        let compose = container.makeScheduleComposeViewModel(user: admin, editing: loaded)
        XCTAssertTrue(compose.isEditing)
        XCTAssertEqual(compose.screenTitle, "일정 수정")
        XCTAssertEqual(compose.submitTitle, "수정 완료")
        XCTAssertEqual(compose.draft.title, "Native 전체 회의")
        XCTAssertEqual(compose.draft.scope, .team)
        XCTAssertEqual(compose.draft.place, "4층 홈베이스")
        XCTAssertTrue(compose.draft.agenda.contains("14:00–14:20 팀 운영 소식 공유"), "안건 원문 그대로")
        XCTAssertTrue(compose.draft.asksRSVP)
        XCTAssertEqual(Calendar.current.component(.hour, from: compose.draft.startsAt), 14)
        XCTAssertEqual(Calendar.current.component(.hour, from: compose.draft.endsAt), 16)
    }

    func testAdminEditsScheduleAndDetailReloads() async throws {
        let container = makeContainer()
        let detail = container.makeScheduleDetailViewModel(scheduleId: 3, user: admin)
        await detail.load()
        let compose = container.makeScheduleComposeViewModel(user: admin, editing: try XCTUnwrap(detail.detail))
        XCTAssertEqual(compose.draft.place, "온라인 · Discode", "장소 상세까지 합쳐서 채워요")

        compose.draft.title = "  Book-on 디자인 리뷰 (시간 변경)  "
        compose.draft.startsAt = time(17, 0, on: compose.draft.date)
        compose.draft.endsAt = time(18, 30, on: compose.draft.date)
        compose.draft.place = "3층 라운지"
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertTrue(compose.didCreate)
        XCTAssertEqual(compose.completionTitle, "일정을 수정했어요")

        let reloaded = container.makeScheduleDetailViewModel(scheduleId: 3, user: admin)
        await reloaded.load()
        let event = try XCTUnwrap(reloaded.detail?.event)
        XCTAssertEqual(event.title, "Book-on 디자인 리뷰 (시간 변경)")
        XCTAssertEqual(event.place, "3층 라운지")
        XCTAssertEqual(Calendar.current.dateComponents([.hour, .minute], from: event.endsAt), DateComponents(hour: 18, minute: 30))
    }

    func testOnlyAdminCanEditSchedule() async throws {
        let container = makeContainer()
        let detail = container.makeScheduleDetailViewModel(scheduleId: 2, user: fa)
        await detail.load()
        XCTAssertFalse(detail.canEdit, "FA 는 수정 버튼이 없어요")
        XCTAssertFalse(container.makeScheduleDetailViewModel(scheduleId: 2).canEdit)

        let compose = container.makeScheduleComposeViewModel(user: fa, editing: try XCTUnwrap(detail.detail))
        await compose.submit()
        XCTAssertFalse(compose.didCreate)
        XCTAssertEqual(compose.errorMessage, "일정은 관리자만 수정할 수 있어요.")
    }

    func testEditKeepsTimeValidation() async throws {
        let container = makeContainer()
        let detail = container.makeScheduleDetailViewModel(scheduleId: 4, user: admin)
        await detail.load()
        let compose = container.makeScheduleComposeViewModel(user: admin, editing: try XCTUnwrap(detail.detail))
        compose.draft.endsAt = time(17, 0, on: compose.draft.date)
        XCTAssertNotNil(compose.timeHint, "끝이 시작(18:00)보다 빠르면 안내해요")
        await compose.submit()
        XCTAssertEqual(compose.errorMessage, "끝나는 시각은 시작 시각보다 뒤로 정해 주세요.")
    }
}
