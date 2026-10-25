import XCTest
@testable import TeamSpace

@MainActor
final class HomeViewModelTests: XCTestCase {
    private func makeViewModel() -> HomeViewModel {
        let tokenStorage = InMemoryTokenStorage()
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
        XCTAssertEqual(home.notices.count, 3)
    }

    func testFinanceModeSwitchesAmount() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let finance = try XCTUnwrap(viewModel.state.value?.finance)

        XCTAssertEqual(viewModel.financeAmount(finance), 3_560_000)
        viewModel.financeMode = .holding
        XCTAssertEqual(viewModel.financeAmount(finance), 8_900_000)
    }

    func testUnknownEnumValuesDoNotBreakDecoding() throws {
        let json = #"""
        {"todayTaskCount":0,"unreadNotificationCount":0,"latestNotification":null,"finance":null,"contracts":null,
         "projects":[],"schedules":[],
         "notices":[{"id":1,"category":"SOMETHING_NEW","title":"새 분류","updatedAt":"2026-10-20T00:00:00Z"}]}
        """#
        let dto = try JSONCoder.makeDecoder().decode(DashboardHomeResponseDTO.self, from: Data(json.utf8))

        let home = dto.toEntity()
        XCTAssertNil(home.finance, "재정 권한이 없으면 finance 가 비어서 와요")
        XCTAssertEqual(home.notices.first?.category, .unknown)
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
