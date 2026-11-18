import SwiftUI

/// 로그인 상태에 따라 시작 화면 / 로그인 흐름 / 메인 탭을 보여줍니다.
struct RootView: View {
    let container: DIContainer
    let session: AppSession
    let entryRouter: NotificationEntryRouter

    /// 07-14 설정의 다크 모드
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
    /// 스플래시: 자동 로그인 확인이 끝나고, 최소 0.9초가 지나면 사라져요
    @State private var splashMinDone = false
    @State private var splashVisible = true

    var body: some View {
        content
            .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
            .animation(.easeInOut(duration: 0.2), value: session.state)
            .task { await session.restore() }
            .overlay {
                if session.isExpiredNoticePresented {
                    SessionExpiredDialog { session.isExpiredNoticePresented = false }
                }
            }
            .animation(.easeOut(duration: 0.2), value: session.isExpiredNoticePresented)
            .overlay {
                if splashVisible {
                    SplashView()
                        .transition(.opacity.combined(with: .scale(scale: 1.04)))
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(900))
                splashMinDone = true
            }
            .onChange(of: splashReady, initial: true) { _, ready in
                guard ready, splashVisible else { return }
                withAnimation(.easeOut(duration: 0.32)) { splashVisible = false }
            }
    }

    private var splashReady: Bool { splashMinDone && session.state != .launching }

    @ViewBuilder
    private var content: some View {
        switch session.state {
        case .launching:
            LaunchView()
        case .signedOut:
            AuthFlowView(
                container: container,
                entry: entryRouter.pending,
                onCancelEntry: { entryRouter.cancel() },
                onLoginSucceeded: { user in session.signIn(user) }
            )
        case .signedIn(let user):
            MainTabView(container: container, user: user, entryRouter: entryRouter, onLogout: { session.signOut() })
        }
    }
}

/// 자동 로그인 확인 중의 바탕 (위에 SplashView가 덮여 있어요)
private struct LaunchView: View {
    var body: some View {
        Color("LaunchBackground").ignoresSafeArea()
    }
}

#Preview {
    let container = DIContainer.preview()
    return RootView(container: container, session: container.makeAppSession(), entryRouter: NotificationEntryRouter())
}
