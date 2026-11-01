import SwiftUI

/// 로그인 상태에 따라 시작 화면 / 로그인 흐름 / 메인 탭을 보여줍니다.
struct RootView: View {
    let container: DIContainer
    let session: AppSession
    let entryRouter: NotificationEntryRouter

    /// 07-14 설정의 다크 모드
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue

    var body: some View {
        content
            .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
            .animation(.easeInOut(duration: 0.2), value: session.state)
            .task { await session.restore() }
    }

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

/// 자동 로그인 확인 중 잠깐 보이는 화면
private struct LaunchView: View {
    var body: some View {
        BrandLogo()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.tsSurface.ignoresSafeArea())
    }
}

#Preview {
    let container = DIContainer.preview()
    return RootView(container: container, session: container.makeAppSession(), entryRouter: NotificationEntryRouter())
}
