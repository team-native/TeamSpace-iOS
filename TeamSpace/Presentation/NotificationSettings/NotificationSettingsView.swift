import SwiftUI

/// 02-9 알림 설정
struct NotificationSettingsView: View {
    @State private var viewModel: NotificationSettingsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: NotificationSettingsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenTitle(
                    title: "어떤 알림을 받을까요?",
                    subtitle: "꺼 둔 알림도 앱 안 알림센터에는 그대로 남아요."
                )
                if let route = viewModel.permissionRoute {
                    PermissionOffBanner(isDenied: route == .notificationTroubleshoot) { onNavigate(route) }
                }
                categoryCard
                QuietHoursCard(description: viewModel.quietHoursDescription, isOn: quietHoursBinding)
                InfoBanner(
                    message: "기기 알림 권한은 iOS 설정 → 알림 → TeamSpace 에서 바꿀 수 있어요.",
                    icon: .infoCircle,
                    style: .muted
                )
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "알림 설정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refreshPermission() } }
        }
        .alert(viewModel.toastMessage ?? "", isPresented: toastBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    private var categoryCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.categories.enumerated()), id: \.element) { index, category in
                if index > 0 { TSDivider() }
                NotificationCategoryToggleRow(category: category, isOn: binding(for: category))
            }
        }
        .tsCard(padding: Spacing.lg)
    }

    private func binding(for category: NotificationSettingCategory) -> Binding<Bool> {
        Binding(
            get: { viewModel.isEnabled(category) },
            set: { isOn in Task { await viewModel.setEnabled(category, isEnabled: isOn) } }
        )
    }

    private var quietHoursBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.quietHours.isEnabled },
            set: { isOn in Task { await viewModel.setQuietHours(isEnabled: isOn) } }
        )
    }

    private var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )
    }
}

#Preview("권한 없음") {
    NavigationStack {
        NotificationSettingsView(
            viewModel: DIContainer.preview(permission: .denied).makeNotificationSettingsViewModel(),
            onNavigate: { _ in }
        )
    }
}

#Preview("권한 허용") {
    NavigationStack {
        NotificationSettingsView(
            viewModel: DIContainer.preview(permission: .authorized).makeNotificationSettingsViewModel(),
            onNavigate: { _ in }
        )
    }
}
