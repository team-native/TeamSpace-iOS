import SwiftUI

/// 07-14 설정 · 07-17 로그아웃 확인
struct SettingsView: View {
    let user: AuthUser
    let onNavigate: (AppRoute) -> Void
    let onLogout: () -> Void

    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
    @State private var isLogoutDialogPresented = false
    @Environment(\.dismiss) private var dismiss

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }

    var body: some View {
        ScrollView {
            settingsList
                .padding(.horizontal, Spacing.screen)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "설정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if isLogoutDialogPresented {
                LogoutDialog(onLogout: onLogout, onCancel: { isLogoutDialogPresented = false })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLogoutDialogPresented)
    }

    private var settingsList: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            SettingsSection(title: "화면") {
                Menu {
                    Picker("다크 모드", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                } label: {
                    SettingsRow(title: "다크 모드", subtitle: currentAppearance.detail, trailing: currentAppearance.title)
                }
            }
            SettingsSection(title: "알림") {
                Button { onNavigate(.notificationSettings) } label: {
                    SettingsRow(title: "알림 설정", subtitle: "종류별로 받을 알림을 골라요")
                }
            }
            SettingsSection(title: "계정") {
                Button { onNavigate(.comingSoon(title: "비밀번호 변경")) } label: { SettingsRow(title: "비밀번호 변경") }
                TSDivider()
                Button { onNavigate(.financeAccess) } label: {
                    SettingsRow(title: "재정 정보 권한", badge: user.financeScopeTitle)
                }
                TSDivider()
                Button { onNavigate(.workspacePermissions) } label: { SettingsRow(title: "내 권한 · 접근 범위") }
            }
            SettingsSection(title: "정보") {
                Button { onNavigate(.comingSoon(title: "공지 · 운영 정책")) } label: { SettingsRow(title: "공지 · 운영 정책") }
                TSDivider()
                SettingsRow(title: "버전", trailing: Self.appVersion, showsChevron: false)
            }
            Button("로그아웃") { isLogoutDialogPresented = true }
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsNegative)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.tsNegativeSoft, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .buttonStyle(.plain)
        }
    }

    /// Info.plist 의 버전 (예: 1.0.0)
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
}

/// 07-17 로그아웃 확인
private struct LogoutDialog: View {
    let onLogout: () -> Void
    let onCancel: () -> Void

    var body: some View {
        TSDialog(onDismiss: onCancel) {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    Text("로그아웃할까요?")
                        .tsFont(.headline)
                        .foregroundStyle(Color.tsInk)
                    Text("다시 로그인하기 전까지 새 알림을 받을 수 없어요.")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: Spacing.sm) {
                    Button("로그아웃", action: onLogout)
                        .buttonStyle(.tsPrimary)
                    Button("취소", action: onCancel)
                        .buttonStyle(.tsSecondary)
                }
            }
            .padding(Spacing.xxl)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(user: AuthUser(id: 1, name: "옥물결", roles: [.member]), onNavigate: { _ in }, onLogout: {})
    }
}
