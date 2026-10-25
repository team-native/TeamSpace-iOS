import Foundation

/// 의존성 조립소. 싱글톤(shared) 없이 앱 시작 시 한 번 만들어 생성자로 주입합니다.
final class DIContainer {
    private let tokenStorage: TokenStorage
    private let authRepository: AuthRepository
    private let notificationRepository: NotificationRepository
    private let notificationSettingsRepository: NotificationSettingsRepository
    private let notificationPermissionRepository: NotificationPermissionRepository
    private let pushTokenRepository: PushTokenRepository
    private let dashboardRepository: DashboardRepository
    private let memberRepository: MemberRepository
    private let financeRepository: FinanceRepository

    init(
        apiClient: APIClient,
        tokenStorage: TokenStorage,
        notificationSettingsRepository: NotificationSettingsRepository = UserDefaultsNotificationSettingsRepository(),
        notificationPermissionRepository: NotificationPermissionRepository = SystemNotificationPermissionRepository()
    ) {
        self.tokenStorage = tokenStorage
        self.authRepository = AuthRepositoryImpl(client: apiClient)
        self.notificationRepository = NotificationRepositoryImpl(client: apiClient)
        self.notificationSettingsRepository = notificationSettingsRepository
        self.notificationPermissionRepository = notificationPermissionRepository
        self.pushTokenRepository = PushTokenRepositoryImpl(client: apiClient)
        self.dashboardRepository = DashboardRepositoryImpl(client: apiClient)
        self.memberRepository = MemberRepositoryImpl(client: apiClient)
        self.financeRepository = FinanceRepositoryImpl(client: apiClient)
    }

    /// xcconfig 의 USE_MOCK_API / API_BASE_URL 에 따라 실서버 또는 Mock 서버를 씁니다.
    static func make(configuration: AppConfiguration = .current) -> DIContainer {
        let tokenStorage = KeychainRepository()
        let apiClient: APIClient
        if !configuration.usesMockAPI, let baseURL = configuration.apiBaseURL {
            apiClient = APIClient(baseURL: baseURL, transport: URLSessionTransport(), tokenStorage: tokenStorage)
        } else {
            apiClient = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(), tokenStorage: tokenStorage)
        }
        return DIContainer(apiClient: apiClient, tokenStorage: tokenStorage)
    }

    /// Preview 전용 (Mock 서버 + 메모리 토큰 + 가짜 알림 권한)
    static func preview(permission: NotificationPermissionStatus = .notDetermined) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let apiClient = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 300_000_000),
            tokenStorage: tokenStorage
        )
        return DIContainer(
            apiClient: apiClient,
            tokenStorage: tokenStorage,
            notificationSettingsRepository: UserDefaultsNotificationSettingsRepository(
                defaults: UserDefaults(suiteName: "preview.notification.settings") ?? .standard
            ),
            notificationPermissionRepository: MockNotificationPermissionRepository(status: permission)
        )
    }

    var loginUseCase: LoginUseCase {
        LoginUseCase(authRepository: authRepository, tokenStorage: tokenStorage)
    }

    var restoreSessionUseCase: RestoreSessionUseCase {
        RestoreSessionUseCase(authRepository: authRepository, tokenStorage: tokenStorage)
    }

    var logoutUseCase: LogoutUseCase {
        LogoutUseCase(tokenStorage: tokenStorage)
    }

    var fetchNotificationsUseCase: FetchNotificationsUseCase {
        FetchNotificationsUseCase(notificationRepository: notificationRepository)
    }

    var markNotificationsReadUseCase: MarkNotificationsReadUseCase {
        MarkNotificationsReadUseCase(notificationRepository: notificationRepository)
    }

    var requestAccountUseCase: RequestAccountUseCase {
        RequestAccountUseCase(authRepository: authRepository)
    }

    var requestPasswordResetUseCase: RequestPasswordResetUseCase {
        RequestPasswordResetUseCase(authRepository: authRepository)
    }

    var fetchNotificationSettingsUseCase: FetchNotificationSettingsUseCase {
        FetchNotificationSettingsUseCase(settingsRepository: notificationSettingsRepository)
    }

    var updateNotificationSettingsUseCase: UpdateNotificationSettingsUseCase {
        UpdateNotificationSettingsUseCase(settingsRepository: notificationSettingsRepository)
    }

    var checkNotificationPermissionUseCase: CheckNotificationPermissionUseCase {
        CheckNotificationPermissionUseCase(permissionRepository: notificationPermissionRepository)
    }

    var requestNotificationPermissionUseCase: RequestNotificationPermissionUseCase {
        RequestNotificationPermissionUseCase(permissionRepository: notificationPermissionRepository)
    }

    var registerPushTokenUseCase: RegisterPushTokenUseCase {
        RegisterPushTokenUseCase(pushTokenRepository: pushTokenRepository)
    }

    var fetchDashboardHomeUseCase: FetchDashboardHomeUseCase {
        FetchDashboardHomeUseCase(dashboardRepository: dashboardRepository)
    }

    var fetchMembersUseCase: FetchMembersUseCase {
        FetchMembersUseCase(memberRepository: memberRepository)
    }

    var fetchMemberDetailUseCase: FetchMemberDetailUseCase {
        FetchMemberDetailUseCase(memberRepository: memberRepository)
    }

    var fetchOrganizationUseCase: FetchOrganizationUseCase {
        FetchOrganizationUseCase(memberRepository: memberRepository)
    }

    var fetchFinanceOverviewUseCase: FetchFinanceOverviewUseCase {
        FetchFinanceOverviewUseCase(financeRepository: financeRepository)
    }

    var fetchContractLedgerUseCase: FetchContractLedgerUseCase {
        FetchContractLedgerUseCase(financeRepository: financeRepository)
    }

    var fetchContractDetailUseCase: FetchContractDetailUseCase {
        FetchContractDetailUseCase(financeRepository: financeRepository)
    }

    var fetchMonthlyFlowsUseCase: FetchMonthlyFlowsUseCase {
        FetchMonthlyFlowsUseCase(financeRepository: financeRepository)
    }

    var fetchProjectAmountsUseCase: FetchProjectAmountsUseCase {
        FetchProjectAmountsUseCase(financeRepository: financeRepository)
    }
}

@MainActor
extension DIContainer {
    func makeAppSession() -> AppSession {
        AppSession(restoreSessionUseCase: restoreSessionUseCase, logoutUseCase: logoutUseCase)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: loginUseCase)
    }

    func makePasswordResetViewModel() -> PasswordResetViewModel {
        PasswordResetViewModel(requestPasswordResetUseCase: requestPasswordResetUseCase)
    }

    func makeAccountRequestViewModel() -> AccountRequestViewModel {
        AccountRequestViewModel(requestAccountUseCase: requestAccountUseCase)
    }

    func makeNotificationCenterViewModel() -> NotificationCenterViewModel {
        NotificationCenterViewModel(
            fetchNotificationsUseCase: fetchNotificationsUseCase,
            markNotificationsReadUseCase: markNotificationsReadUseCase
        )
    }

    func makeNotificationSettingsViewModel() -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(
            fetchSettingsUseCase: fetchNotificationSettingsUseCase,
            updateSettingsUseCase: updateNotificationSettingsUseCase,
            checkPermissionUseCase: checkNotificationPermissionUseCase
        )
    }

    func makeNotificationPermissionViewModel() -> NotificationPermissionViewModel {
        NotificationPermissionViewModel(
            fetchSettingsUseCase: fetchNotificationSettingsUseCase,
            updateSettingsUseCase: updateNotificationSettingsUseCase,
            requestPermissionUseCase: requestNotificationPermissionUseCase
        )
    }

    func makeNotificationTroubleshootViewModel() -> NotificationTroubleshootViewModel {
        NotificationTroubleshootViewModel(
            fetchSettingsUseCase: fetchNotificationSettingsUseCase,
            checkPermissionUseCase: checkNotificationPermissionUseCase
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(fetchDashboardHomeUseCase: fetchDashboardHomeUseCase)
    }

    func makeMemberDirectoryViewModel() -> MemberDirectoryViewModel {
        MemberDirectoryViewModel(
            fetchMembersUseCase: fetchMembersUseCase,
            fetchOrganizationUseCase: fetchOrganizationUseCase
        )
    }

    func makeMemberDetailViewModel(memberId: Int) -> MemberDetailViewModel {
        MemberDetailViewModel(memberId: memberId, fetchMemberDetailUseCase: fetchMemberDetailUseCase)
    }

    func makeFinanceViewModel(user: AuthUser) -> FinanceViewModel {
        FinanceViewModel(user: user, fetchFinanceOverviewUseCase: fetchFinanceOverviewUseCase)
    }

    func makeContractLedgerViewModel(year: Int) -> ContractLedgerViewModel {
        ContractLedgerViewModel(year: year, fetchContractLedgerUseCase: fetchContractLedgerUseCase)
    }

    func makeContractDetailViewModel(contractId: Int) -> ContractDetailViewModel {
        ContractDetailViewModel(contractId: contractId, fetchContractDetailUseCase: fetchContractDetailUseCase)
    }

    func makeMonthlyFlowViewModel(endMonth: Date) -> MonthlyFlowViewModel {
        MonthlyFlowViewModel(endMonth: endMonth, fetchMonthlyFlowsUseCase: fetchMonthlyFlowsUseCase)
    }

    func makeFinanceCompositionViewModel(month: Date) -> FinanceCompositionViewModel {
        FinanceCompositionViewModel(month: month, fetchFinanceOverviewUseCase: fetchFinanceOverviewUseCase)
    }

    func makeFinanceAccessViewModel(user: AuthUser, year: Int = Calendar.current.component(.year, from: Date())) -> FinanceAccessViewModel {
        FinanceAccessViewModel(year: year, user: user, fetchContractLedgerUseCase: fetchContractLedgerUseCase)
    }

    func makeProjectAmountsViewModel(year: Int, user: AuthUser) -> ProjectAmountsViewModel {
        ProjectAmountsViewModel(year: year, user: user, fetchProjectAmountsUseCase: fetchProjectAmountsUseCase)
    }
}
