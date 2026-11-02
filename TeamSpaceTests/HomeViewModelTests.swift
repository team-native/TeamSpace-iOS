import XCTest
@testable import TeamSpace

@MainActor
final class HomeViewModelTests: XCTestCase {
    private func makeViewModel(isFA: Bool = true) -> HomeViewModel {
        let tokenStorage = InMemoryTokenStorage()
        if isFA {
            try? tokenStorage.save(AuthToken(accessToken: MockTransport.faToken, refreshToken: "r"), persistent: false)
        }
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage).makeHomeViewModel()
    }

    func testLoadDashboardFromMock() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        guard case .loaded(let home) = viewModel.state else {
            return XCTFail("홈을 불러와야 해요: \(viewModel.state)")
        }
        XCTAssertEqual(viewModel.unreadNotificationCount, 3)
        XCTAssertEqual(viewModel.greeting(for: "옥물결"), "옥물결 님, 오늘 확인할 일이 3건 있어요.")
        XCTAssertEqual(home.finance?.pools.map(\.kind), [.operation, .reserve, .dividend])
        XCTAssertEqual(home.projects.first?.name, "MoSS", "마감이 가까운 프로젝트가 먼저 와요")
        XCTAssertEqual(home.notices.count, 3, "공지는 /notices 에서 3개")
        XCTAssertEqual(home.latestNotification?.type, .approval)
        XCTAssertEqual(home.schedules.map(\.title), ["주간 팀 회의", "IoT 학과 홍보 홈페이지 납품"])
        XCTAssertEqual(home.finance?.trend.count, 7, "/finance/summary 의 월별 수입")
        XCTAssertEqual(home.finance?.monthIncome, 7_260_000)
        XCTAssertNotNil(home.contracts)
        XCTAssertEqual(Set(home.contracts?.recentContracts.map(\.id) ?? []).count, home.contracts?.recentContracts.count)
    }

    func testMemberSeesHomeWithoutFinance() async {
        let viewModel = makeViewModel(isFA: false)

        await viewModel.load()

        let home = viewModel.state.value
        XCTAssertNotNil(home)
        XCTAssertNil(home?.finance, "FA 가 아니면 dashboard 에 finance 가 없어요")
        XCTAssertNil(home?.contracts)
        XCTAssertEqual(home?.projects.count, 2)
    }

    func testFinanceModeSwitchesAmount() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let finance = try XCTUnwrap(viewModel.state.value?.finance)

        XCTAssertEqual(viewModel.financeAmount(finance), 3_560_000)
        viewModel.financeMode = .holding
        XCTAssertEqual(viewModel.financeAmount(finance), 8_900_000)
    }

    func testDashboardDecodingFromServer() throws {
        let json = #"""
        {"me":{"id":1},"summary":{"todoCount":4,"todayTodoCount":"2","unreadNotifications":7,"receivedApprovalCount":0,
          "notice":{"id":"5","kind":"공지","title":"정기 회의","createdAt":"2026-10-20T00:00:00Z"},"schedule":null},
         "todos":[],"notifications":[{"id":"9","kind":"재정","title":"입금","createdAt":"2026-10-20T00:00:00+00:00",
          "href":"/inhouse/finance/receipts","unread":true}],
         "approvals":[],"events":[{"id":"x-broken"},{"id":"3","title":"회의","date":"2999-01-02","time":"10:00","place":"4층"}],
         "projects":[{"id":"8","name":"Book-on","desc":"독서 앱 · 2026.08 – 2026.11","due":"","progress":140,"members":[1,2]}]}
        """#
        let dto = try JSONCoder.makeDecoder().decode(ServerDashboardHomeDTO.self, from: Data(json.utf8))
        let home = dto.toEntity(finance: nil, contracts: nil, notices: nil)

        XCTAssertFalse(dto.canSeeFinance, "finance 가 없으면 재정 카드를 숨겨요")
        XCTAssertEqual(home.todayTaskCount, 2)
        XCTAssertEqual(home.unreadNotificationCount, 7)
        XCTAssertEqual(home.latestNotification?.type, .finance)
        XCTAssertEqual(home.schedules.map(\.id), [3], "깨진 일정은 건너뛰어요")
        XCTAssertEqual(home.schedules.first?.place, "4층")
        XCTAssertEqual(home.projects.first?.progress, 100)
        XCTAssertEqual(home.projects.first?.memberCount, 2)
        let due = try XCTUnwrap(home.projects.first?.dueDate)
        XCTAssertEqual(Calendar.current.dateComponents([.year, .month, .day], from: due), DateComponents(year: 2026, month: 11, day: 30))
        XCTAssertEqual(home.notices.map(\.title), ["정기 회의"], "공지 목록을 못 받으면 최신 공지 하나")
    }

    func testFormats() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        XCTAssertEqual(TSFormat.won(3_560_000), "3,560,000원")
        XCTAssertEqual(TSFormat.signedWon(-3_480_000), "-3,480,000원")
        XCTAssertEqual(TSFormat.signedPercent(12.8), "+12.8%")
        XCTAssertEqual(TSFormat.dDay(now.addingTimeInterval(27 * 86_400), now: now, calendar: calendar), "D-27")
        XCTAssertEqual(TSFormat.dDay(now, now: now, calendar: calendar), "D-Day")
        XCTAssertEqual(TSFormat.updated(now.addingTimeInterval(-86_400), now: now, calendar: calendar), "어제 업데이트")
    }
}
