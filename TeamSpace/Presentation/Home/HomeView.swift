import SwiftUI

/// 02-1 홈
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let user: AuthUser
    private let onNavigate: (AppRoute) -> Void
    private let onSelectTab: (MainTab) -> Void
    private let onLogout: () -> Void

    @State private var isLogoutConfirmPresented = false

    init(
        viewModel: HomeViewModel,
        user: AuthUser,
        onNavigate: @escaping (AppRoute) -> Void,
        onSelectTab: @escaping (MainTab) -> Void,
        onLogout: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.user = user
        self.onNavigate = onNavigate
        self.onSelectTab = onSelectTab
        self.onLogout = onLogout
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HomeHeader(
                    unreadCount: viewModel.unreadNotificationCount,
                    onBell: { onNavigate(.notificationCenter) },
                    onAvatar: { isLogoutConfirmPresented = true }
                )
                HomeGreeting(message: viewModel.greeting(for: user.name))
                    .padding(.vertical, Spacing.sm)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabBarInset)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .confirmationDialog("로그아웃할까요?", isPresented: $isLogoutConfirmPresented, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive, action: onLogout)
            Button("취소", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 240)
        case .loaded(let home):
            HomeSections(
                home: home,
                financeMode: $viewModel.financeMode,
                financeAmount: home.finance.map { viewModel.financeAmount($0) } ?? 0,
                onNavigate: onNavigate,
                onSelectTab: onSelectTab
            )
        case .empty, .forbidden:
            InfoBanner(message: "홈 정보를 볼 수 있는 권한이 없어요. 운영진에게 문의해 주세요.", icon: .infoCircle, style: .muted)
        case .failed(let error):
            HomeErrorView(message: error.userMessage) {
                Task { await viewModel.load() }
            }
        }
    }
}

/// 불러오기 실패 — 재시도 버튼 (컨벤션: 오류 화면 재시도 제공)
private struct HomeErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .multilineTextAlignment(.center)
            Button("다시 시도", action: onRetry)
                .buttonStyle(.ts(.soft, size: .small, fullWidth: false))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    HomeView(
        viewModel: DIContainer.preview().makeHomeViewModel(),
        user: AuthUser(id: 1, name: "옥물결", roles: [.member]),
        onNavigate: { _ in },
        onSelectTab: { _ in },
        onLogout: {}
    )
}
