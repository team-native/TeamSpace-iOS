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
    private let approvalRepository: ApprovalRepository
    private let libraryRepository: LibraryRepository
    private let recentSearchRepository: RecentSearchRepository
    private let workspaceRepository: WorkspaceRepository
    private let projectRepository: ProjectRepository
    private let ruleRepository: RuleRepository
    private let boardRepository: BoardRepository
    private let boardRecentSearchRepository: RecentSearchRepository
    private let postDraftRepository: PostDraftRepository

    init(
        apiClient: APIClient,
        tokenStorage: TokenStorage,
        notificationSettingsRepository: NotificationSettingsRepository = UserDefaultsNotificationSettingsRepository(),
        notificationPermissionRepository: NotificationPermissionRepository = SystemNotificationPermissionRepository(),
        recentSearchRepository: RecentSearchRepository = UserDefaultsRecentSearchRepository(),
        boardRecentSearchRepository: RecentSearchRepository = UserDefaultsRecentSearchRepository(
            key: UserDefaultsRecentSearchRepository.boardKey
        ),
        postDraftRepository: PostDraftRepository = UserDefaultsPostDraftRepository()
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
        self.approvalRepository = ApprovalRepositoryImpl(client: apiClient)
        self.libraryRepository = LibraryRepositoryImpl(client: apiClient)
        self.recentSearchRepository = recentSearchRepository
        self.workspaceRepository = WorkspaceRepositoryImpl(client: apiClient)
        self.projectRepository = ProjectRepositoryImpl(client: apiClient)
        self.ruleRepository = RuleRepositoryImpl(client: apiClient)
        self.boardRepository = BoardRepositoryImpl(client: apiClient)
        self.boardRecentSearchRepository = boardRecentSearchRepository
        self.postDraftRepository = postDraftRepository
    }

    /// xcconfig 의 USE_MOCK_API / API_BASE_URL 에 따라 실서버 또는 Mock 서버를 씁니다.
    static func make(configuration: AppConfiguration = .current) -> DIContainer {
        let tokenStorage = KeychainRepository()
        let apiClient: APIClient
        var recentSearchSeed: [String] = []
        var boardSearchSeed: [String] = []
        if !configuration.usesMockAPI, let baseURL = configuration.apiBaseURL {
            apiClient = APIClient(baseURL: baseURL, transport: URLSessionTransport(), tokenStorage: tokenStorage)
        } else {
            apiClient = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(), tokenStorage: tokenStorage)
            recentSearchSeed = MockLibraryFixture.recentKeywords
            boardSearchSeed = MockBoardStore.recentKeywords
        }
        return DIContainer(
            apiClient: apiClient,
            tokenStorage: tokenStorage,
            recentSearchRepository: UserDefaultsRecentSearchRepository(seed: recentSearchSeed),
            boardRecentSearchRepository: UserDefaultsRecentSearchRepository(
                key: UserDefaultsRecentSearchRepository.boardKey,
                seed: boardSearchSeed
            )
        )
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
            notificationPermissionRepository: MockNotificationPermissionRepository(status: permission),
            recentSearchRepository: UserDefaultsRecentSearchRepository(
                defaults: UserDefaults(suiteName: "preview.library.search") ?? .standard,
                seed: MockLibraryFixture.recentKeywords
            ),
            boardRecentSearchRepository: UserDefaultsRecentSearchRepository(
                defaults: UserDefaults(suiteName: "preview.board.search") ?? .standard,
                key: UserDefaultsRecentSearchRepository.boardKey,
                seed: MockBoardStore.recentKeywords
            ),
            postDraftRepository: UserDefaultsPostDraftRepository(
                defaults: UserDefaults(suiteName: "preview.board.draft") ?? .standard
            )
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

    var fetchApprovalBoxUseCase: FetchApprovalBoxUseCase {
        FetchApprovalBoxUseCase(approvalRepository: approvalRepository)
    }

    var fetchApprovalDetailUseCase: FetchApprovalDetailUseCase {
        FetchApprovalDetailUseCase(approvalRepository: approvalRepository)
    }

    var decideApprovalUseCase: DecideApprovalUseCase {
        DecideApprovalUseCase(approvalRepository: approvalRepository)
    }

    var addApprovalCommentUseCase: AddApprovalCommentUseCase {
        AddApprovalCommentUseCase(approvalRepository: approvalRepository)
    }

    var withdrawApprovalUseCase: WithdrawApprovalUseCase {
        WithdrawApprovalUseCase(approvalRepository: approvalRepository)
    }

    var submitDocumentUseCase: SubmitDocumentUseCase {
        SubmitDocumentUseCase(approvalRepository: approvalRepository)
    }

    var fetchLibraryUseCase: FetchLibraryUseCase {
        FetchLibraryUseCase(libraryRepository: libraryRepository)
    }

    var searchLibraryUseCase: SearchLibraryUseCase {
        SearchLibraryUseCase(libraryRepository: libraryRepository)
    }

    var recentSearchUseCase: RecentSearchUseCase {
        RecentSearchUseCase(recentSearchRepository: recentSearchRepository)
    }

    var fetchWorkspaceHomeUseCase: FetchWorkspaceHomeUseCase {
        FetchWorkspaceHomeUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchJoinedProjectsUseCase: FetchJoinedProjectsUseCase {
        FetchJoinedProjectsUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchMyDocumentsUseCase: FetchMyDocumentsUseCase {
        FetchMyDocumentsUseCase(workspaceRepository: workspaceRepository)
    }

    var deleteDraftUseCase: DeleteDraftUseCase {
        DeleteDraftUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchSchedulesUseCase: FetchSchedulesUseCase {
        FetchSchedulesUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchScheduleDetailUseCase: FetchScheduleDetailUseCase {
        FetchScheduleDetailUseCase(workspaceRepository: workspaceRepository)
    }

    var respondScheduleUseCase: RespondScheduleUseCase {
        RespondScheduleUseCase(workspaceRepository: workspaceRepository)
    }

    var updateRemindersUseCase: UpdateRemindersUseCase {
        UpdateRemindersUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchActivitySummaryUseCase: FetchActivitySummaryUseCase {
        FetchActivitySummaryUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchMyPostsUseCase: FetchMyPostsUseCase {
        FetchMyPostsUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchMyProposalsUseCase: FetchMyProposalsUseCase {
        FetchMyProposalsUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchProfileUseCase: FetchProfileUseCase {
        FetchProfileUseCase(workspaceRepository: workspaceRepository)
    }

    var updateProfileUseCase: UpdateProfileUseCase {
        UpdateProfileUseCase(workspaceRepository: workspaceRepository)
    }

    var fetchProjectsUseCase: FetchProjectsUseCase {
        FetchProjectsUseCase(projectRepository: projectRepository)
    }

    var fetchProjectDetailUseCase: FetchProjectDetailUseCase {
        FetchProjectDetailUseCase(projectRepository: projectRepository)
    }

    var fetchProjectTimelineUseCase: FetchProjectTimelineUseCase {
        FetchProjectTimelineUseCase(projectRepository: projectRepository)
    }

    var fetchRecruitmentUseCase: FetchRecruitmentUseCase {
        FetchRecruitmentUseCase(projectRepository: projectRepository)
    }

    var applyProjectUseCase: ApplyProjectUseCase {
        ApplyProjectUseCase(projectRepository: projectRepository)
    }

    var fetchMyApplicationsUseCase: FetchMyApplicationsUseCase {
        FetchMyApplicationsUseCase(projectRepository: projectRepository)
    }

    var cancelApplicationUseCase: CancelApplicationUseCase {
        CancelApplicationUseCase(projectRepository: projectRepository)
    }

    var fetchApplicantsUseCase: FetchApplicantsUseCase {
        FetchApplicantsUseCase(projectRepository: projectRepository)
    }

    var decideApplicantUseCase: DecideApplicantUseCase {
        DecideApplicantUseCase(projectRepository: projectRepository)
    }

    var fetchBoardUseCase: FetchBoardUseCase {
        FetchBoardUseCase(boardRepository: boardRepository)
    }

    var searchBoardUseCase: SearchBoardUseCase {
        SearchBoardUseCase(boardRepository: boardRepository)
    }

    var fetchPostDetailUseCase: FetchPostDetailUseCase {
        FetchPostDetailUseCase(boardRepository: boardRepository)
    }

    var togglePostLikeUseCase: TogglePostLikeUseCase {
        TogglePostLikeUseCase(boardRepository: boardRepository)
    }

    var reportPostUseCase: ReportPostUseCase {
        ReportPostUseCase(boardRepository: boardRepository)
    }

    var deletePostUseCase: DeletePostUseCase {
        DeletePostUseCase(boardRepository: boardRepository)
    }

    var createPostUseCase: CreatePostUseCase {
        CreatePostUseCase(boardRepository: boardRepository, postDraftRepository: postDraftRepository)
    }

    var postDraftUseCase: PostDraftUseCase {
        PostDraftUseCase(postDraftRepository: postDraftRepository)
    }

    var createCommentUseCase: CreateCommentUseCase {
        CreateCommentUseCase(boardRepository: boardRepository)
    }

    var boardRecentSearchUseCase: RecentSearchUseCase {
        RecentSearchUseCase(recentSearchRepository: boardRecentSearchRepository)
    }

    var fetchRulesUseCase: FetchRulesUseCase {
        FetchRulesUseCase(ruleRepository: ruleRepository)
    }

    var fetchRuleDetailUseCase: FetchRuleDetailUseCase {
        FetchRuleDetailUseCase(ruleRepository: ruleRepository)
    }

    var acknowledgeRuleUseCase: AcknowledgeRuleUseCase {
        AcknowledgeRuleUseCase(ruleRepository: ruleRepository)
    }

    var fetchTodosUseCase: FetchTodosUseCase {
        FetchTodosUseCase(workspaceRepository: workspaceRepository)
    }

    var toggleTodoUseCase: ToggleTodoUseCase {
        ToggleTodoUseCase(workspaceRepository: workspaceRepository)
    }

    var addTodoUseCase: AddTodoUseCase {
        AddTodoUseCase(workspaceRepository: workspaceRepository)
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

    func makeApprovalListViewModel() -> ApprovalListViewModel {
        ApprovalListViewModel(fetchApprovalBoxUseCase: fetchApprovalBoxUseCase)
    }

    func makeApprovalDetailViewModel(documentId: Int) -> ApprovalDetailViewModel {
        ApprovalDetailViewModel(
            documentId: documentId,
            fetchApprovalDetailUseCase: fetchApprovalDetailUseCase,
            decideApprovalUseCase: decideApprovalUseCase,
            addApprovalCommentUseCase: addApprovalCommentUseCase,
            withdrawApprovalUseCase: withdrawApprovalUseCase
        )
    }

    func makeExpenseRequestViewModel() -> ExpenseRequestViewModel {
        ExpenseRequestViewModel(submitDocumentUseCase: submitDocumentUseCase)
    }

    func makeStaffingRequestViewModel() -> StaffingRequestViewModel {
        StaffingRequestViewModel(submitDocumentUseCase: submitDocumentUseCase)
    }

    func makeRequestFormViewModel(kind: RequestFormKind, initialTitle: String = "") -> RequestFormViewModel {
        RequestFormViewModel(kind: kind, submitDocumentUseCase: submitDocumentUseCase, initialTitle: initialTitle)
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(fetchLibraryUseCase: fetchLibraryUseCase)
    }

    func makeLibrarySearchViewModel() -> LibrarySearchViewModel {
        LibrarySearchViewModel(searchLibraryUseCase: searchLibraryUseCase, recentSearchUseCase: recentSearchUseCase)
    }

    func makeTemplateDetailViewModel(templateId: Int) -> TemplateDetailViewModel {
        TemplateDetailViewModel(
            templateId: templateId,
            fetchTemplateUseCase: FetchLibraryTemplateUseCase(libraryRepository: libraryRepository)
        )
    }

    func makeWorkspaceHomeViewModel(user: AuthUser) -> WorkspaceHomeViewModel {
        WorkspaceHomeViewModel(user: user, fetchWorkspaceHomeUseCase: fetchWorkspaceHomeUseCase)
    }

    func makeTodoListViewModel(userName: String) -> TodoListViewModel {
        TodoListViewModel(
            userName: userName,
            fetchTodosUseCase: fetchTodosUseCase,
            toggleTodoUseCase: toggleTodoUseCase,
            addTodoUseCase: addTodoUseCase
        )
    }

    func makeWorkspaceMenuViewModel(user: AuthUser) -> WorkspaceMenuViewModel {
        WorkspaceMenuViewModel(
            user: user,
            fetchApprovalBoxUseCase: fetchApprovalBoxUseCase,
            fetchWorkspaceHomeUseCase: fetchWorkspaceHomeUseCase
        )
    }

    func makeWorkspaceProjectsViewModel() -> WorkspaceProjectsViewModel {
        WorkspaceProjectsViewModel(fetchJoinedProjectsUseCase: fetchJoinedProjectsUseCase)
    }

    func makeMyDocumentsViewModel() -> MyDocumentsViewModel {
        MyDocumentsViewModel(fetchMyDocumentsUseCase: fetchMyDocumentsUseCase)
    }

    func makeDraftDocumentsViewModel() -> DraftDocumentsViewModel {
        DraftDocumentsViewModel(fetchMyDocumentsUseCase: fetchMyDocumentsUseCase, deleteDraftUseCase: deleteDraftUseCase)
    }

    func makeScheduleCalendarViewModel() -> ScheduleCalendarViewModel {
        ScheduleCalendarViewModel(
            fetchSchedulesUseCase: fetchSchedulesUseCase,
            respondScheduleUseCase: respondScheduleUseCase
        )
    }

    func makeScheduleDetailViewModel(scheduleId: Int) -> ScheduleDetailViewModel {
        ScheduleDetailViewModel(
            scheduleId: scheduleId,
            fetchScheduleDetailUseCase: fetchScheduleDetailUseCase,
            respondScheduleUseCase: respondScheduleUseCase,
            updateRemindersUseCase: updateRemindersUseCase
        )
    }

    func makeActivitySummaryViewModel() -> ActivitySummaryViewModel {
        ActivitySummaryViewModel(fetchActivitySummaryUseCase: fetchActivitySummaryUseCase)
    }

    func makeMyPostsViewModel(userName: String) -> MyPostsViewModel {
        MyPostsViewModel(userName: userName, fetchMyPostsUseCase: fetchMyPostsUseCase)
    }

    func makeMyProposalsViewModel(userName: String) -> MyProposalsViewModel {
        MyProposalsViewModel(userName: userName, fetchMyProposalsUseCase: fetchMyProposalsUseCase)
    }

    func makeProfileEditViewModel() -> ProfileEditViewModel {
        ProfileEditViewModel(fetchProfileUseCase: fetchProfileUseCase, updateProfileUseCase: updateProfileUseCase)
    }

    func makePermissionsViewModel(user: AuthUser) -> PermissionsViewModel {
        PermissionsViewModel(user: user, fetchProfileUseCase: fetchProfileUseCase)
    }

    func makeProjectListViewModel() -> ProjectListViewModel {
        ProjectListViewModel(fetchProjectsUseCase: fetchProjectsUseCase, fetchProfileUseCase: fetchProfileUseCase)
    }

    func makeProjectDetailViewModel(projectId: Int) -> ProjectDetailViewModel {
        ProjectDetailViewModel(projectId: projectId, fetchProjectDetailUseCase: fetchProjectDetailUseCase)
    }

    func makeProjectTimelineViewModel(projectId: Int) -> ProjectTimelineViewModel {
        ProjectTimelineViewModel(projectId: projectId, fetchProjectTimelineUseCase: fetchProjectTimelineUseCase)
    }

    func makeRecruitmentViewModel(projectId: Int) -> RecruitmentViewModel {
        RecruitmentViewModel(
            projectId: projectId,
            fetchRecruitmentUseCase: fetchRecruitmentUseCase,
            applyProjectUseCase: applyProjectUseCase
        )
    }

    func makeMyApplicationsViewModel() -> MyApplicationsViewModel {
        MyApplicationsViewModel(
            fetchMyApplicationsUseCase: fetchMyApplicationsUseCase,
            cancelApplicationUseCase: cancelApplicationUseCase
        )
    }

    func makeApplicantReviewViewModel(projectId: Int) -> ApplicantReviewViewModel {
        ApplicantReviewViewModel(
            projectId: projectId,
            fetchApplicantsUseCase: fetchApplicantsUseCase,
            decideApplicantUseCase: decideApplicantUseCase
        )
    }

    func makeRuleListViewModel() -> RuleListViewModel {
        RuleListViewModel(fetchRulesUseCase: fetchRulesUseCase)
    }

    func makeRuleDetailViewModel(ruleId: Int) -> RuleDetailViewModel {
        RuleDetailViewModel(
            ruleId: ruleId,
            fetchRuleDetailUseCase: fetchRuleDetailUseCase,
            acknowledgeRuleUseCase: acknowledgeRuleUseCase
        )
    }

    func makeBoardViewModel() -> BoardViewModel {
        BoardViewModel(fetchBoardUseCase: fetchBoardUseCase)
    }

    func makeBoardSearchViewModel() -> BoardSearchViewModel {
        BoardSearchViewModel(searchBoardUseCase: searchBoardUseCase, recentSearchUseCase: boardRecentSearchUseCase)
    }

    func makePostDetailViewModel(postId: Int) -> PostDetailViewModel {
        PostDetailViewModel(
            postId: postId,
            fetchPostDetailUseCase: fetchPostDetailUseCase,
            togglePostLikeUseCase: togglePostLikeUseCase,
            reportPostUseCase: reportPostUseCase,
            deletePostUseCase: deletePostUseCase
        )
    }

    func makePostComposeViewModel() -> PostComposeViewModel {
        PostComposeViewModel(createPostUseCase: createPostUseCase, postDraftUseCase: postDraftUseCase)
    }

    func makeCommentComposeViewModel(postId: Int, userName: String) -> CommentComposeViewModel {
        CommentComposeViewModel(
            postId: postId,
            userName: userName,
            fetchPostDetailUseCase: fetchPostDetailUseCase,
            createCommentUseCase: createCommentUseCase
        )
    }
}
