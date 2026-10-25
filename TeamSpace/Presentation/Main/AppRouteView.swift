import SwiftUI

/// AppRoute → 실제 화면. ViewModel 은 DIContainer 가 만들어 줍니다.
/// body 가 50줄을 넘지 않도록 섹션별로 나눠서 그려요.
struct AppRouteView: View {
    let route: AppRoute
    let container: DIContainer
    /// 권한에 따라 화면이 달라지는 곳(04 재무)과 내 이름이 필요한 곳(07 내 공간)에서 사용
    let user: AuthUser
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        switch route {
        case .notificationCenter, .notificationSettings, .notificationPermission, .notificationTroubleshoot:
            notificationScreen
        case .memberDirectory, .memberDetail:
            memberScreen
        case .financeContractLedger, .financeContractDetail, .financeMonthlyFlow, .financeComposition,
             .financeAccess, .financeProjectAmounts:
            financeScreen
        case .approvalDetail, .approvalCompose, .librarySearch, .templateDetail, .templateCompose:
            documentScreen
        case .workspaceTodos:
            TodoListView(viewModel: container.makeTodoListViewModel(userName: user.name), onNavigate: onNavigate)
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
}
