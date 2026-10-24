import SwiftUI

/// 로그인 전에는 로그인 화면, 성공하면 다음 화면으로 넘어갑니다.
/// 홈 화면이 생기면 `SignedInPlaceholderView` 를 교체하세요.
struct RootView: View {
    let container: DIContainer
    @State private var signedInUser: AuthUser?

    var body: some View {
        Group {
            if let signedInUser {
                SignedInPlaceholderView(user: signedInUser)
            } else {
                AuthFlowView(container: container, onLoginSucceeded: { user in signedInUser = user })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: signedInUser)
    }
}

/// 임시 화면 — 로그인 성공 확인용
private struct SignedInPlaceholderView: View {
    let user: AuthUser

    var body: some View {
        VStack(spacing: Spacing.sm) {
            BrandLogo()
            Text("\(user.name) 님, 로그인됐어요.")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            Text("홈 화면은 다음 이슈에서 연결해요.")
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tsSurface.ignoresSafeArea())
    }
}

#Preview {
    RootView(container: .preview())
}
