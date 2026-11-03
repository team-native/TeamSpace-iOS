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
}
