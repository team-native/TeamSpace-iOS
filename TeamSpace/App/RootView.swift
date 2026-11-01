import SwiftUI

/// 로그인 상태에 따라 시작 화면 / 로그인 흐름 / 메인 탭을 보여줍니다.
struct RootView: View {
    let container: DIContainer
    let session: AppSession

    var body: some View {
        content
            .animation(.easeInOut(duration: 0.2), value: session.state)
            .task { await session.restore() }
    }

    @ViewBuilder
    private var content: some View {
        switch session.state {
        case .launching:
            LaunchView()
        case .signedOut:
            AuthFlowView(container: container, onLoginSucceeded: { user in session.signIn(user) })
        case .signedIn(let user):
            MainTabView(container: container, user: user, onLogout: { session.signOut() })
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
    return RootView(container: container, session: container.makeAppSession())
}
