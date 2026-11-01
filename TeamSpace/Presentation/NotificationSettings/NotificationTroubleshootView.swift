import SwiftUI
import UIKit

/// 02-7 알림 수신 진단 (기기에서 알림이 꺼져 있을 때)
struct NotificationTroubleshootView: View {
    @State private var viewModel: NotificationTroubleshootViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: NotificationTroubleshootViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                TroubleshootHeader(isResolved: viewModel.isResolved)
                DiagnosisCard(diagnoses: viewModel.diagnoses)
                if !viewModel.isResolved {
                    Button("기기 설정 열기", action: openSystemSettings)
                        .buttonStyle(.ts(.soft, size: .medium))
                    TroubleshootChecklist()
                }
                if let message = viewModel.recheckMessage {
                    InfoBanner(message: message, icon: .infoCircle, style: .muted)
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "알림 수신 진단", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, phase in
            // 기기 설정에서 돌아오면 자동으로 다시 확인
            if phase == .active { Task { await viewModel.load() } }
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.xs) {
            Button(viewModel.isResolved ? "완료" : "앱으로 돌아와 다시 확인") {
                if viewModel.isResolved {
                    dismiss()
                } else {
                    Task { await viewModel.recheck() }
                }
            }
            .buttonStyle(.tsPrimaryLarge)

            Button("앱 안 알림센터 보기") { onNavigate(.notificationCenter) }
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk3)
                .padding(.vertical, Spacing.sm)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.md)
        .background(Color.tsBackground)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
    }
}

#Preview("꺼짐") {
    NavigationStack {
        NotificationTroubleshootView(
            viewModel: DIContainer.preview(permission: .denied).makeNotificationTroubleshootViewModel(),
            onNavigate: { _ in }
        )
    }
}

#Preview("해결됨") {
    NavigationStack {
        NotificationTroubleshootView(
            viewModel: DIContainer.preview(permission: .authorized).makeNotificationTroubleshootViewModel(),
            onNavigate: { _ in }
        )
    }
}
