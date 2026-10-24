import SwiftUI

/// 홈 (임시) — 02-1 홈 디자인이 확정되면 교체합니다.
struct HomeView: View {
    let user: AuthUser
    let onNavigate: (AppRoute) -> Void
    let onLogout: () -> Void

    @State private var isLogoutConfirmPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                BrandLogo()
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(user.name) 님, 반가워요.")
                        .tsFont(.title2)
                        .foregroundStyle(Color.tsInk)
                    Text("홈 화면은 디자인이 확정되면 채워질 예정이에요.")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk2)
                }
                InfoBanner(message: "알림 · 팀원 · 재무 화면은 다음 이슈에서 하나씩 연결돼요.")
                Button("로그아웃") { isLogoutConfirmPresented = true }
                    .buttonStyle(.tsSecondary)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.tabBarInset)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("로그아웃할까요?", isPresented: $isLogoutConfirmPresented, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive, action: onLogout)
            Button("취소", role: .cancel) {}
        }
    }
}

#Preview {
    HomeView(user: AuthUser(id: 1, name: "홍길동", roles: [.member]), onNavigate: { _ in }, onLogout: {})
}
