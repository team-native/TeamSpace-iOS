import XCTest
@testable import TeamSpace

@MainActor
final class NotificationSettingsTests: XCTestCase {
    /// 테스트마다 새 저장 공간을 씁니다.
    private let suiteName = "test.notification.settings.\(UUID().uuidString)"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private func makeContainer(
        permission: NotificationPermissionRepository,
        tokenStorage: InMemoryTokenStorage = InMemoryTokenStorage()
    ) -> DIContainer {
        addTeardownBlock { [suiteName] in
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(
            apiClient: client,
            tokenStorage: tokenStorage,
            notificationSettingsRepository: UserDefaultsNotificationSettingsRepository(defaults: defaults),
            notificationPermissionRepository: permission
        )
    }

    // MARK: 02-9 알림 설정

    func testSettingsDefaultsToAllOnAndSendsToPermissionScreen() async {
        let viewModel = makeContainer(permission: MockNotificationPermissionRepository(status: .notDetermined))
            .makeNotificationSettingsViewModel()

        await viewModel.load()

        XCTAssertTrue(NotificationSettingCategory.allCases.allSatisfy { viewModel.isEnabled($0) })
        XCTAssertEqual(viewModel.permissionRoute, .notificationPermission)
        XCTAssertEqual(viewModel.quietHoursDescription, "22:00 – 08:00 에는 소리 없이 받아요")
    }

    func testDeniedPermissionSendsToTroubleshoot() async {
        let viewModel = makeContainer(permission: MockNotificationPermissionRepository(status: .denied))
            .makeNotificationSettingsViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.permissionRoute, .notificationTroubleshoot)
    }

    func testToggleIsSavedAndRestored() async {
        let permission = MockNotificationPermissionRepository(status: .authorized)
        let first = makeContainer(permission: permission).makeNotificationSettingsViewModel()
        await first.load()

        await first.setEnabled(.finance, isEnabled: false)
        await first.setQuietHours(isEnabled: false)

        let second = makeContainer(permission: permission).makeNotificationSettingsViewModel()
        await second.load()
        XCTAssertFalse(second.isEnabled(.finance))
        XCTAssertTrue(second.isEnabled(.notice))
        XCTAssertFalse(second.settings.quietHours.isEnabled)
        XCTAssertNil(second.permissionRoute)
    }

    // MARK: 02-6 알림 권한

    func testRequestPermissionGranted() async {
        let permission = MockNotificationPermissionRepository(status: .notDetermined, grantsOnRequest: true)
        let viewModel = makeContainer(permission: permission).makeNotificationPermissionViewModel()

        let result = await viewModel.requestPermission()

        XCTAssertEqual(result, .authorized)
        XCTAssertEqual(permission.requestCount, 1)
        XCTAssertFalse(viewModel.isRequesting)
    }

    func testRequestPermissionDenied() async {
        let permission = MockNotificationPermissionRepository(status: .notDetermined, grantsOnRequest: false)
        let viewModel = makeContainer(permission: permission).makeNotificationPermissionViewModel()

        let result = await viewModel.requestPermission()

        XCTAssertEqual(result, .denied)
    }

    func testLockScreenPreviewIsSaved() async {
        let permission = MockNotificationPermissionRepository()
        let viewModel = makeContainer(permission: permission).makeNotificationPermissionViewModel()
        await viewModel.load()
        XCTAssertEqual(viewModel.lockScreenPreview, .hideSensitive)

        await viewModel.select(.showContent)

        let settings = await UserDefaultsNotificationSettingsRepository(defaults: defaults).fetch()
        XCTAssertEqual(settings.lockScreenPreview, .showContent)
    }

    // MARK: 02-7 수신 진단

    func testTroubleshootRecheckAfterUserTurnsOnInSettings() async {
        let permission = MockNotificationPermissionRepository(status: .denied)
        let viewModel = makeContainer(permission: permission).makeNotificationTroubleshootViewModel()
        await viewModel.load()
        XCTAssertFalse(viewModel.isResolved)
        XCTAssertEqual(viewModel.diagnoses.first?.level, .problem)

        await viewModel.recheck()
        XCTAssertNotNil(viewModel.recheckMessage, "아직 꺼져 있으면 안내를 보여줘요")

        permission.simulateSystemChange(to: .authorized)
        await viewModel.recheck()
        XCTAssertTrue(viewModel.isResolved)
        XCTAssertNil(viewModel.recheckMessage)
    }

    // MARK: 푸시 토큰

    func testRegisterPushTokenRequiresLogin() async throws {
        let tokenStorage = InMemoryTokenStorage()
        let container = makeContainer(permission: MockNotificationPermissionRepository(), tokenStorage: tokenStorage)

        do {
            try await container.registerPushTokenUseCase.execute(token: "abc123")
            XCTFail("로그인 전에는 401 이어야 해요")
        } catch {
            guard case .unauthorized = error as? AppError else {
                return XCTFail("unauthorized 가 와야 해요: \(error)")
            }
        }

        try tokenStorage.save(AuthToken(accessToken: "a", refreshToken: "r"), persistent: false)
        try await container.registerPushTokenUseCase.execute(token: "abc123")
    }

    func testEmptyPushTokenIsRejected() async {
        let container = makeContainer(permission: MockNotificationPermissionRepository())
        do {
            try await container.registerPushTokenUseCase.execute(token: "")
            XCTFail("빈 토큰은 보내지 않아요")
        } catch {
            XCTAssertNotNil(error as? AppError)
        }
    }

    // MARK: 방해 금지 시간

    func testQuietHoursAcrossMidnight() {
        let quietHours = QuietHours.default
        XCTAssertTrue(quietHours.contains(hour: 23))
        XCTAssertTrue(quietHours.contains(hour: 3))
        XCTAssertFalse(quietHours.contains(hour: 8))
        XCTAssertFalse(quietHours.contains(hour: 15))
        XCTAssertFalse(QuietHours(isEnabled: false, startHour: 22, endHour: 8).contains(hour: 23))
    }
}
