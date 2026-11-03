import SwiftUI

/// AppRoute → 실제 화면. ViewModel 은 DIContainer 가 만들어 줍니다.
/// body 가 50줄을 넘지 않도록 섹션별로 나눠서 그려요.
struct AppRouteView: View {
    let route: AppRoute
    let container: DIContainer
    /// 권한에 따라 화면이 달라지는 곳(04 재무)과 내 이름이 필요한 곳(07 내 공간)에서 사용
    let user: AuthUser
    let onNavigate: (AppRoute) -> Void
    /// 07-17 로그아웃
    var onLogout: () -> Void = {}

    var body: some View {
        switch route {
        case .notificationCenter, .notificationSettings, .notificationPermission, .notificationTroubleshoot:
            notificationScreen
        case .memberDirectory, .memberDetail:
            memberScreen
        case .financeContractLedger, .financeContractDetail, .financeMonthlyFlow, .financeComposition,
             .financeAccess, .financeProjectAmounts:
            financeScreen
        case .approvalDetail, .approvalCompose, .approvalEdit, .librarySearch, .templateDetail, .templateCompose:
            documentScreen
        case .workspaceDashboard, .workspaceTodos, .workspaceDocuments, .workspaceDrafts, .workspaceProjects, .workspaceProjectList,
             .workspaceSchedules, .scheduleCompose, .scheduleEdit, .workspaceScheduleDetail, .workspaceMyPosts, .workspaceMyProposals, .workspaceActivity:
            workspaceScreen
        case .workspaceProfile, .workspaceSettings, .workspacePermissions, .passwordChange:
            accountScreen
        case .projects, .projectDetail, .projectCompose, .projectEdit, .projectOpenings, .projectTimeline, .projectRecruitment, .myApplications, .applicantReview:
            projectScreen
        case .rules, .ruleDetail, .ruleComparison, .ruleCompose, .ruleEdit:
            ruleScreen
        case .board, .boardSearch, .postDetail, .postCompose, .postEdit, .commentCompose:
            boardScreen
        case .notices, .noticeDetail, .noticeCompose, .noticeEdit:
            noticeScreen
        case .myInquiries, .inquiryCompose, .inquiryDetail, .inquiryInbox, .reportList, .signupRequests, .financePermissions, .inquiryReview:
            inquiryScreen
        case .proposals, .proposalDetail, .proposalCompose:
            proposalScreen
        case .integratedSearch:
            IntegratedSearchView(viewModel: container.makeIntegratedSearchViewModel(), onNavigate: onNavigate)
        case .comingSoon(let title):
            ComingSoonView(title: title, showsBackButton: true)
        }
    }

    /// 02 알림
    @ViewBuilder
    private var notificationScreen: some View {
        switch route {
        case .notificationSettings:
            NotificationSettingsView(viewModel: container.makeNotificationSettingsViewModel(), onNavigate: onNavigate)
        case .notificationPermission:
            NotificationPermissionView(viewModel: container.makeNotificationPermissionViewModel(), onNavigate: onNavigate)
        case .notificationTroubleshoot:
            NotificationTroubleshootView(
                viewModel: container.makeNotificationTroubleshootViewModel(),
                onNavigate: onNavigate
            )
        default:
            NotificationCenterView(viewModel: container.makeNotificationCenterViewModel(), onNavigate: onNavigate)
        }
    }

    /// 03 팀원
    @ViewBuilder
    private var memberScreen: some View {
        if case .memberDetail(let id) = route {
            MemberDetailView(viewModel: container.makeMemberDetailViewModel(memberId: id), onNavigate: onNavigate)
        } else {
            MemberDirectoryView(viewModel: container.makeMemberDirectoryViewModel(), onNavigate: onNavigate)
        }
    }

    /// 04 재무
    @ViewBuilder
    private var financeScreen: some View {
        let year = Calendar.current.component(.year, from: Date())
        switch route {
        case .financeContractDetail(let id):
            ContractDetailView(viewModel: container.makeContractDetailViewModel(contractId: id), onNavigate: onNavigate)
        case .financeMonthlyFlow(let month):
            MonthlyFlowView(viewModel: container.makeMonthlyFlowViewModel(endMonth: month))
        case .financeComposition(let month):
            FinanceCompositionView(viewModel: container.makeFinanceCompositionViewModel(month: month))
        case .financeAccess:
            FinanceAccessView(viewModel: container.makeFinanceAccessViewModel(user: user), onNavigate: onNavigate)
        case .financeProjectAmounts:
            ProjectAmountsView(
                viewModel: container.makeProjectAmountsViewModel(year: year, user: user),
                onNavigate: onNavigate
            )
        default:
            ContractLedgerView(viewModel: container.makeContractLedgerViewModel(year: year), onNavigate: onNavigate)
        }
    }

    /// 05 결재 · 06 문서함
    @ViewBuilder
    private var documentScreen: some View {
        switch route {
        case .approvalDetail(let documentId):
            ApprovalDetailView(viewModel: container.makeApprovalDetailViewModel(documentId: documentId), onNavigate: onNavigate)
        case .approvalEdit(let documentId):
            ApprovalEditView(viewModel: container.makeApprovalDetailViewModel(documentId: documentId), container: container, onNavigate: onNavigate)
        case .librarySearch:
            LibrarySearchView(viewModel: container.makeLibrarySearchViewModel(), onNavigate: onNavigate)
        case .templateDetail(let id):
            TemplateDetailView(viewModel: container.makeTemplateDetailViewModel(templateId: id), onNavigate: onNavigate)
        case .templateCompose(let kind, let title):
            if let composeKind = kind.composeKind {
                ApprovalComposeView(
                    container: container,
                    onNavigate: onNavigate,
                    initialKind: composeKind,
                    templateTitle: title
                )
            } else {
                InfoBanner(message: "아직 지원하지 않는 템플릿이에요.", icon: .infoCircle, style: .muted)
            }
        default:
            ApprovalComposeView(container: container, onNavigate: onNavigate)
        }
    }

    /// 07 내 공간
    @ViewBuilder
    private var workspaceScreen: some View {
        switch route {
        case .workspaceTodos:
            TodoListView(viewModel: container.makeTodoListViewModel(userName: user.name), onNavigate: onNavigate)
        case .workspaceDocuments:
            MyDocumentsView(viewModel: container.makeMyDocumentsViewModel(), onNavigate: onNavigate)
        case .workspaceDrafts:
            DraftDocumentsView(viewModel: container.makeDraftDocumentsViewModel(), onNavigate: onNavigate)
        case .workspaceSchedules:
            ScheduleCalendarView(viewModel: container.makeScheduleCalendarViewModel(user: user), onNavigate: onNavigate)
        case .scheduleCompose:
            ScheduleComposeView(viewModel: container.makeScheduleComposeViewModel(user: user))
        case .scheduleEdit(let id):
            ScheduleEditView(viewModel: container.makeScheduleDetailViewModel(scheduleId: id, user: user), container: container, user: user)
        case .workspaceScheduleDetail(let id):
            ScheduleDetailView(viewModel: container.makeScheduleDetailViewModel(scheduleId: id, user: user), onNavigate: onNavigate)
        case .workspaceMyPosts:
            MyPostsView(viewModel: container.makeMyPostsViewModel(userName: user.name), onNavigate: onNavigate)
        case .workspaceMyProposals:
            MyProposalsView(viewModel: container.makeMyProposalsViewModel(userName: user.name), onNavigate: onNavigate)
        case .workspaceActivity:
            ActivitySummaryView(viewModel: container.makeActivitySummaryViewModel(), onNavigate: onNavigate)
        case .workspaceProjects:
            WorkspaceProjectsView(viewModel: container.makeWorkspaceProjectsViewModel(), onNavigate: onNavigate)
        case .workspaceProjectList:
            WorkspaceProjectListView(viewModel: container.makeWorkspaceProjectListViewModel(), onNavigate: onNavigate)
        default:
            WorkspaceHomeView(viewModel: container.makeWorkspaceHomeViewModel(user: user), onNavigate: onNavigate)
        }
    }

    /// 07-13 ~ 07-17 프로필 · 설정 · 권한
    @ViewBuilder
    private var accountScreen: some View {
        switch route {
        case .workspaceProfile:
            ProfileEditView(viewModel: container.makeProfileEditViewModel())
        case .passwordChange:
            PasswordChangeView(viewModel: container.makePasswordChangeViewModel())
        case .workspacePermissions:
            PermissionsView(viewModel: container.makePermissionsViewModel(user: user), onNavigate: onNavigate)
        default:
            SettingsView(user: user, onNavigate: onNavigate, onLogout: onLogout)
        }
    }

    /// 08 프로젝트
    @ViewBuilder
    private var projectScreen: some View {
        switch route {
        case .projectDetail(let id):
            ProjectDetailView(
                viewModel: container.makeProjectDetailViewModel(projectId: id),
                canReviewApplicants: user.can(.manageProject),
                canEdit: user.can(.registerProjects),
                onNavigate: onNavigate
            )
        case .projectCompose:
            ProjectComposeView(viewModel: container.makeProjectComposeViewModel(user: user))
        case .projectOpenings(let id):
            ProjectOpeningsView(viewModel: container.makeProjectOpeningsViewModel(projectId: id, user: user))
        case .projectEdit(let id):
            ProjectEditView(viewModel: container.makeProjectDetailViewModel(projectId: id), container: container, user: user)
        case .projectRecruitment(let id):
            RecruitmentView(viewModel: container.makeRecruitmentViewModel(projectId: id), onNavigate: onNavigate)
        case .myApplications:
            MyApplicationsView(viewModel: container.makeMyApplicationsViewModel(), onNavigate: onNavigate)
        case .applicantReview(let projectId):
            ApplicantReviewView(viewModel: container.makeApplicantReviewViewModel(projectId: projectId))
        case .projectTimeline(let id):
            ProjectTimelineView(viewModel: container.makeProjectTimelineViewModel(projectId: id), onNavigate: onNavigate)
        default:
            ProjectListView(viewModel: container.makeProjectListViewModel(), canRegister: user.can(.registerProjects), onNavigate: onNavigate)
        }
    }

    /// 09 규칙
    @ViewBuilder
    private var ruleScreen: some View {
        switch route {
        case .ruleDetail(let id):
            RuleDetailView(viewModel: container.makeRuleDetailViewModel(ruleId: id), canEdit: user.can(.manageDocs), onNavigate: onNavigate)
        case .ruleCompose:
            RuleComposeView(viewModel: container.makeRuleComposeViewModel(user: user))
        case .ruleEdit(let id):
            RuleEditView(viewModel: container.makeRuleDetailViewModel(ruleId: id), container: container, user: user)
        case .ruleComparison(let id):
            RuleComparisonView(viewModel: container.makeRuleDetailViewModel(ruleId: id), onNavigate: onNavigate)
        default:
            RuleListView(viewModel: container.makeRuleListViewModel(), canRegister: user.can(.manageDocs), onNavigate: onNavigate)
        }
    }

    /// 10 게시판 · 공지
    @ViewBuilder
    private var boardScreen: some View {
        switch route {
        case .boardSearch:
            BoardSearchView(viewModel: container.makeBoardSearchViewModel(), onNavigate: onNavigate)
        case .postDetail(let id):
            PostDetailView(viewModel: container.makePostDetailViewModel(postId: id), onNavigate: onNavigate)
        case .postCompose:
            PostComposeView(viewModel: container.makePostComposeViewModel(), onNavigate: onNavigate)
        case .postEdit(let id):
            PostEditView(viewModel: container.makePostDetailViewModel(postId: id), container: container, onNavigate: onNavigate)
        case .commentCompose(let postId):
            CommentComposeView(viewModel: container.makeCommentComposeViewModel(postId: postId, userName: user.name))
        default:
            BoardView(viewModel: container.makeBoardViewModel(), onNavigate: onNavigate)
        }
    }

    /// 10-5 ~ 10-7 공지
    @ViewBuilder
    private var noticeScreen: some View {
        switch route {
        case .noticeDetail(let id):
            NoticeDetailView(viewModel: container.makeNoticeDetailViewModel(noticeId: id, user: user), onNavigate: onNavigate)
        case .noticeCompose:
            NoticeComposeView(viewModel: container.makeNoticeComposeViewModel(user: user))
        case .noticeEdit(let id):
            NoticeEditView(viewModel: container.makeNoticeDetailViewModel(noticeId: id, user: user), container: container, user: user)
        default:
            NoticeListView(viewModel: container.makeNoticeListViewModel(user: user), onNavigate: onNavigate)
        }
    }

    /// 11 문의 · 건의
    @ViewBuilder
    private var inquiryScreen: some View {
        switch route {
        case .inquiryCompose(let context):
            InquiryComposeView(viewModel: container.makeInquiryComposeViewModel(context: context), onNavigate: onNavigate)
        case .inquiryDetail(let id):
            InquiryDetailView(viewModel: container.makeInquiryDetailViewModel(inquiryId: id), onNavigate: onNavigate)
        case .inquiryInbox:
            InquiryInboxView(viewModel: container.makeInquiryInboxViewModel(user: user), onNavigate: onNavigate)
        case .reportList:
            ReportListView(viewModel: container.makeReportListViewModel(user: user), onNavigate: onNavigate)
        case .signupRequests:
            SignupRequestListView(viewModel: container.makeSignupRequestListViewModel(user: user))
        case .financePermissions:
            FinancePermissionView(viewModel: container.makeFinancePermissionViewModel(user: user))
        case .inquiryReview(let id):
            InquiryReviewView(viewModel: container.makeInquiryReviewViewModel(inquiryId: id, user: user))
        default:
            MyInquiriesView(viewModel: container.makeMyInquiriesViewModel(), onNavigate: onNavigate)
        }
    }

    /// 12 운영 제안
    @ViewBuilder
    private var proposalScreen: some View {
        switch route {
        case .proposalDetail(let id):
            ProposalDetailView(viewModel: container.makeProposalDetailViewModel(proposalId: id, user: user))
        case .proposalCompose:
            ProposalComposeView(viewModel: container.makeProposalComposeViewModel(), onNavigate: onNavigate)
        default:
            ProposalListView(viewModel: container.makeProposalListViewModel(), onNavigate: onNavigate)
        }
    }
}
