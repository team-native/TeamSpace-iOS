import SwiftUI

/// 로그인 후 메인 — 하단 플로팅 탭바 + 탭별 NavigationStack
struct MainTabView: View {
    let container: DIContainer
    let user: AuthUser
    let entryRouter: NotificationEntryRouter
    let onLogout: () -> Void

    @State private var selectedTab: MainTab = .home
    @State private var paths: [MainTab: [AppRoute]] = [:]

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases) { tab in
                NavigationStack(path: pathBinding(for: tab)) {
                    rootView(for: tab)
                        .navigationDestination(for: AppRoute.self) { route in
                            AppRouteView(route: route, container: container, user: user, onNavigate: { push($0, in: tab) })
                        }
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(tab)
            }
        }
        .overlay(alignment: .bottom) {
            if isTabBarVisible {
                TSTabBar(items: MainTab.allCases.map(\.tabBarItem), selection: tabSelection)
                    .padding(.bottom, Spacing.xxs)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isTabBarVisible)
        .onChange(of: entryRouter.pending, initial: true) { _, entry in
            if entry != nil { openPendingEntry() }
        }
    }

    /// 알림을 눌러 들어왔으면 홈 → 알림 센터 → 목적지 순으로 열어요. (02-8)
    private func openPendingEntry() {
        guard let entry = entryRouter.take() else { return }
        selectedTab = .home
        paths[.home] = [.notificationCenter, .comingSoon(title: entry.type.targetTitle)]
    }

    @ViewBuilder
    private func rootView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeView(
                viewModel: container.makeHomeViewModel(),
                user: user,
                onNavigate: { push($0, in: .home) },
                onSelectTab: { selectedTab = $0 },
                onLogout: onLogout
            )
        case .finance:
            FinanceView(
                viewModel: container.makeFinanceViewModel(user: user),
                onNavigate: { push($0, in: .finance) },
                onSelectTab: { selectedTab = $0 }
            )
        case .approval:
            ApprovalListView(viewModel: container.makeApprovalListViewModel(), onNavigate: { push($0, in: .approval) })
        case .documents:
            LibraryView(viewModel: container.makeLibraryViewModel(), onNavigate: { push($0, in: .documents) })
        case .workspace:
            WorkspaceHomeView(
                viewModel: container.makeWorkspaceHomeViewModel(user: user),
                onNavigate: { push($0, in: .workspace) }
            )
        }
    }

    /// 각 탭의 첫 화면에서만 탭바를 보여줍니다.
    private var isTabBarVisible: Bool {
        paths[selectedTab, default: []].isEmpty
    }

    /// 이미 선택된 탭을 한 번 더 누르면 첫 화면으로 돌아갑니다.
    private var tabSelection: Binding<String> {
        Binding(
            get: { selectedTab.rawValue },
            set: { newValue in
                guard let tab = MainTab(rawValue: newValue) else { return }
                if tab == selectedTab {
                    paths[tab] = []
                }
                selectedTab = tab
            }
        )
    }

    private func pathBinding(for tab: MainTab) -> Binding<[AppRoute]> {
        Binding(
            get: { paths[tab, default: []] },
            set: { paths[tab] = $0 }
        )
    }

    private func push(_ route: AppRoute, in tab: MainTab) {
        paths[tab, default: []].append(route)
    }
}

#Preview {
    MainTabView(
        container: .preview(),
        user: AuthUser(id: 1, name: "홍길동", roles: [.member]),
        entryRouter: NotificationEntryRouter(),
        onLogout: {}
    )
}
