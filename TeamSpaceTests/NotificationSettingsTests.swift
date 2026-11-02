import XCTest
@testable import TeamSpace

@MainActor
final class NotificationSettingsTests: XCTestCase {
    /// 테스트마다 새 저장 공간을 씁니다.
    private let suiteName = "test.notification.settings.\(UUID().uuidString)"

    /// 같은 테스트 안에서는 서버(Mock) 저장 내용을 이어 써요.
    private let transport = MockTransport(latencyNanoseconds: 0)

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
            transport: transport,
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
        XCTAssertEqual(viewModel.quietHoursDescription, "23:00 – 08:00 에는 소리 없이 받아요", "서버 기본값 23:00 ~ 08:00")
    }

    func testDeniedPermissionSendsToTroubleshoot() async {
        let viewModel = makeContainer(permission: MockNotificationPermissionRepository(status: .denied))
            .makeNotificationSettingsViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.permissionRoute, .notificationTroubleshoot)
    }

    func testServerValueWinsOverDeviceCache() async throws {
        try await UserDefaultsNotificationSettingsRepository(defaults: defaults).save(
            NotificationSettings(enabledCategories: [], quietHours: .default, lockScreenPreview: .showContent)
        )
        let viewModel = makeContainer(permission: MockNotificationPermissionRepository(status: .authorized))
            .makeNotificationSettingsViewModel()

        await viewModel.load()

        XCTAssertTrue(viewModel.isEnabled(.finance), "서버 kinds 가 기준이에요")
        XCTAssertFalse(viewModel.isEnabled(.rule), "규칙은 서버에 없어 기기 값 그대로")
        XCTAssertEqual(viewModel.settings.lockScreenPreview, .showContent, "잠금 화면 미리보기도 기기 값")
    }

    func testPatchBodySendsOnlyServerKinds() throws {
        var settings = NotificationSettings.default
        settings.set(.rule, isEnabled: false)
        settings.set(.finance, isEnabled: false)
        settings.quietHours = QuietHours(isEnabled: true, startHour: 7, endHour: 9)

        let data = try JSONEncoder().encode(ServerNotificationSettingsPatchDTO(settings))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kinds"] as? [String: Bool], ["내 업무": true, "재정": false, "일정": true, "공지": true])
        XCTAssertEqual(json["dnd"] as? Bool, true)
        XCTAssertEqual(json["dndFrom"] as? String, "07:00")
        XCTAssertEqual(json["dndTo"] as? String, "09:00")
        XCTAssertNil(json["push"], "push · dndDays 는 건드리지 않아요")
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
