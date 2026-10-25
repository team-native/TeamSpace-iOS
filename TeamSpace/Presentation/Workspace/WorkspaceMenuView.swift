import SwiftUI

/// 07-3 내 공간 (내 공간 탭 첫 화면)
struct WorkspaceMenuView: View {
    @State private var viewModel: WorkspaceMenuViewModel
    private let onNavigate: (AppRoute) -> Void
    private let onSelectTab: (MainTab) -> Void

    init(
        viewModel: WorkspaceMenuViewModel,
        onNavigate: @escaping (AppRoute) -> Void,
        onSelectTab: @escaping (MainTab) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
        self.onSelectTab = onSelectTab
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("내 공간")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    CircleIconButton(icon: .settings, accessibilityLabel: "설정", background: .tsSurface, hasBorder: true) {
                        onNavigate(.comingSoon(title: "설정"))
                    }
                }
                .frame(height: 44)
                .padding(.top, Spacing.xs)
                WorkspaceMenuProfileCard(
                    name: viewModel.user.name,
                    affiliation: viewModel.affiliation,
                    onEdit: { onNavigate(.comingSoon(title: "프로필 편집")) }
                )
                ReceivedApprovalCard(
                    count: viewModel.waitingApprovals.count,
                    latest: viewModel.latestWaiting,
                    onOpenTab: { onSelectTab(.approval) },
                    onOpenItem: { onNavigate(.approvalDetail(documentId: $0.id)) }
                )
                WorkspaceMenuList(onNavigate: onNavigate)
                WorkspacePrivacyNote()
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.tabBarInset)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        WorkspaceMenuView(
            viewModel: DIContainer.preview().makeWorkspaceMenuViewModel(
                user: AuthUser(id: 1, name: "옥물결", roles: [.member])
            ),
            onNavigate: { _ in },
            onSelectTab: { _ in }
        )
    }
}
