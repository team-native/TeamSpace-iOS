import SwiftUI

/// AppRoute → 실제 화면. ViewModel 은 DIContainer 가 만들어 줍니다.
struct AppRouteView: View {
    let route: AppRoute
    let container: DIContainer
    /// 권한에 따라 화면이 달라지는 곳(04 재무)에서 사용
    let user: AuthUser
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        switch route {
        case .notificationCenter:
            NotificationCenterView(viewModel: container.makeNotificationCenterViewModel(), onNavigate: onNavigate)
        case .notificationSettings:
            NotificationSettingsView(viewModel: container.makeNotificationSettingsViewModel(), onNavigate: onNavigate)
        case .notificationPermission:
            NotificationPermissionView(viewModel: container.makeNotificationPermissionViewModel(), onNavigate: onNavigate)
        case .notificationTroubleshoot:
            NotificationTroubleshootView(
                viewModel: container.makeNotificationTroubleshootViewModel(),
                onNavigate: onNavigate
            )
        case .memberDirectory:
            MemberDirectoryView(viewModel: container.makeMemberDirectoryViewModel(), onNavigate: onNavigate)
        case .memberDetail(let id):
            MemberDetailView(viewModel: container.makeMemberDetailViewModel(memberId: id), onNavigate: onNavigate)
        case .financeContractLedger:
            ContractLedgerView(
                viewModel: container.makeContractLedgerViewModel(year: Calendar.current.component(.year, from: Date())),
                onNavigate: onNavigate
            )
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
                viewModel: container.makeProjectAmountsViewModel(year: Calendar.current.component(.year, from: Date()), user: user),
                onNavigate: onNavigate
            )
        case .approvalDetail(let documentId):
            ApprovalDetailView(viewModel: container.makeApprovalDetailViewModel(documentId: documentId), onNavigate: onNavigate)
        case .approvalCompose:
            ApprovalComposeView(container: container, onNavigate: onNavigate)
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
        case .comingSoon(let title):
            ComingSoonView(title: title, showsBackButton: true)
        }
    }
}
